import 'package:carer/models/sgv.dart';
import 'package:carer/predictors/regressions.dart';
import 'package:carer/utils/math.dart';

abstract class Predictor {
  const Predictor();

  // Returns the predicted value at mins
  Future<SGV?> predictAt(double timestamp);

  // Returns all predicted values until mins
  Future<List<SGV>> predictRange(List<double> timestamp) async {
    List<Future<SGV?>> predictionFutures = [];
    for (var ts in timestamp) {
      predictionFutures.add(predictAt(ts));
    }

    List<SGV> predictions = [];
    for (var pf in predictionFutures) {
      var p = await pf;
      if (p == null) continue;
      predictions.add(p);
    }
    return predictions;
  }

  Future<List<SGV>> predictNextHour() async {
    var lastSGV = await SGV.lastSGV();

    if (lastSGV == null) {
      return [];
    }
    var times = List.generate(
        12,
        (i) => lastSGV.date
            .add(Duration(minutes: (i + 1) * 5))
            .millisecondsSinceEpoch
            .toDouble());

    return predictRange(times);
  }

  Future<double> rmse(List<double> futureX, List<double> futureY) async {
    var sgvs = await predictRange(futureX);
    var predictions = sgvs.map((s) => s.value * 1.0).toList();
    return Math.rootMeanSquaredError(futureX, futureY, predictions);
  }
}

// This predictor just returns the value of the current
class FlatPredictor extends Predictor {
  const FlatPredictor();

  @override
  Future<SGV?> predictAt(double timestamp) async {
    var lastSGV = await SGV.lastSGV();
    if (lastSGV == null) {
      return null;
    }

    return SGV(
        value: lastSGV.value,
        date: DateTime.fromMillisecondsSinceEpoch(timestamp.toInt()));
  }
}

class GradientPredictor extends Predictor {
  const GradientPredictor();

  @override
  Future<SGV?> predictAt(double timestamp) async {
    var lastSGV = await SGV.lastSGV();
    if (lastSGV == null || lastSGV.rate5m == null) {
      return null;
    }

    // Using the lastSGV and rate5m to rearrage to formula y = ax + c
    // x is timestamp, y is the predicted value, c = -ax1 + y1
    double x1 = lastSGV.date.millisecondsSinceEpoch.toDouble();
    double y1 = lastSGV.value.toDouble();
    double slope =
        lastSGV.rate5m!.toDouble() / (5 * 60 * 1000); // rate5m is in mg/dL/min

    // Calculate c using the formula c = -ax1 + y1
    double c = -slope * x1 + y1;

    DateTime newXDate = DateTime.fromMillisecondsSinceEpoch(timestamp.toInt());
    int newYValue = (slope * timestamp + c).toInt();
    int limitedValue = newYValue.clamp(20, 500);
    return SGV(value: limitedValue, date: newXDate);
  }
}

abstract class RegressionPredictor extends Predictor {
  BestMatchRegression createRegression(List<double> x, List<double> y);

  double fnX(num x) => x / 60000.0;
  int fnRX(double x) => (x * 60000.0).toInt();

  @override
  Future<SGV?> predictAt(double timestamp) async {
    // Very ineffienct
    var sgvs = await SGV.query(limit: 5);
    if (sgvs.length < 2) {
      return null;
    }

    var x = sgvs.map((s) => fnX(s.date.millisecondsSinceEpoch)).toList();
    var y = sgvs.map((s) => s.value * 1.0).toList();
    var r = createRegression(x, y);
    print(r);
    var pred = r.predict(fnX(timestamp));
    int limitedValue = pred.toInt().clamp(20, 500);
    return SGV(
        value: limitedValue,
        date: DateTime.fromMillisecondsSinceEpoch(timestamp.toInt()));
  }
}

class BestRegressionPredictor extends RegressionPredictor {
  BestRegressionPredictor();

  @override
  BestMatchRegression createRegression(List<double> x, List<double> y) {
    return BestMatchRegression(x, y);
  }

  @override
  String toString() => 'BestRegression';
}
