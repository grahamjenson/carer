import 'package:carer/models/sgv.dart';
import 'package:carer/predictors/regressions.dart';
import 'package:carer/utils/math.dart';
import 'package:clock/clock.dart';

abstract class Predictor {
  Predictor();

  // set this to get the cadence of sgv predictinos correct
  DateTime _lastReadingDate = DateTime.now();

  // Get all the expencive calls done here, and can be repedtly called when new data arrives
  Future<void> init();

  // Returns the predicted value at mins
  SGV? predictAt(double timestamp);

  DateTime get lastReadingDate => _lastReadingDate;

  // Returns all predicted values until mins
  List<SGV> predictRange(List<double> timestamp) {
    List<SGV> predictions = [];
    for (var ts in timestamp) {
      var p = predictAt(ts);
      if (p != null) {
        predictions.add(p);
      }
    }
    return predictions;
  }

  List<SGV> predictNextHour() {
    var times = List.generate(
        12,
        (i) => lastReadingDate
            .add(Duration(minutes: (i + 1) * 5))
            .millisecondsSinceEpoch
            .toDouble());

    return predictRange(times);
  }

  Future<double> rmse(List<double> futureX, List<double> futureY) async {
    var sgvs = predictRange(futureX);
    var predictions = sgvs.map((s) => s.value * 1.0).toList();
    return Math.rootMeanSquaredError(futureX, futureY, predictions);
  }
}

// This predictor just returns the value of the current
class FlatPredictor extends Predictor {
  FlatPredictor();
  SGV? lastSGV;

  @override
  Future<void> init() async {
    lastSGV = await SGV.lastSGV();
    if (lastSGV != null) _lastReadingDate = lastSGV!.date;
  }

  @override
  SGV? predictAt(double timestamp) {
    if (lastSGV == null) {
      return null;
    }

    return SGV(
        value: lastSGV!.value,
        date: DateTime.fromMillisecondsSinceEpoch(timestamp.toInt()));
  }
}

class GradientPredictor extends Predictor {
  GradientPredictor();
  SGV? lastSGV;

  @override
  Future<void> init() async {
    lastSGV = await SGV.lastSGV();
    if (lastSGV != null) _lastReadingDate = lastSGV!.date;
  }

  @override
  SGV? predictAt(double timestamp) {
    if (lastSGV == null || lastSGV!.rate5m == null) {
      return null;
    }

    // Using the lastSGV and rate5m to rearrage to formula y = ax + c
    // x is timestamp, y is the predicted value, c = -ax1 + y1
    double x1 = lastSGV!.date.millisecondsSinceEpoch.toDouble();
    double y1 = lastSGV!.value.toDouble();
    double slope =
        lastSGV!.rate5m!.toDouble() / (5 * 60 * 1000); // rate5m is in mg/dL/min

    // Calculate c using the formula c = -ax1 + y1
    double c = -slope * x1 + y1;

    DateTime newXDate = DateTime.fromMillisecondsSinceEpoch(timestamp.toInt());
    int newYValue = (slope * timestamp + c).toInt();
    int limitedValue = newYValue.clamp(20, 500);
    return SGV(value: limitedValue, date: newXDate);
  }
}

abstract class RegressionPredictor extends Predictor {
  Regression createRegression(List<double> x, List<double> y);
  final int pastReadings;
  final double mimnutesFromEpochToLastWeek =
      clock.now().subtract(const Duration(days: 7)).millisecondsSinceEpoch /
          60000;

  RegressionPredictor({this.pastReadings = 5});

  Regression? regression;
  // When processing very large numbers, by squaring and cubing this can cause lots of issues
  // These functions drop x from milliseconds since epoch to
  double fnX(num x) =>
      (x / 60000.0).round().toDouble() - mimnutesFromEpochToLastWeek;
  int fnRX(double x) =>
      (x * 60000.0).toInt() + mimnutesFromEpochToLastWeek.toInt();

  List<SGV> sgvs = [];

  @override
  Future<void> init() async {
    sgvs = await SGV.query(limit: pastReadings);
    if (sgvs.isEmpty) {
      return;
    }
    _lastReadingDate = sgvs.first.date;

    var x = sgvs.map((s) => fnX(s.date.millisecondsSinceEpoch)).toList();
    var y = sgvs.map((s) => s.value * 1.0).toList();
    print("$x, $y");
    regression = createRegression(x, y);
  }

  @override
  SGV? predictAt(double timestamp) {
    if (regression == null) {
      return null;
    }
    // Very ineffienct
    var pred = regression!.predict(fnX(timestamp));
    int limitedValue = pred.toInt().clamp(20, 500);
    return SGV(
        value: limitedValue,
        date: DateTime.fromMillisecondsSinceEpoch(timestamp.toInt()));
  }
}

class BestRegressionPredictor extends RegressionPredictor {
  BestRegressionPredictor();

  @override
  Regression createRegression(List<double> x, List<double> y) {
    return BestMatchRegression(x, y);
  }

  @override
  String toString() => 'BestRegression';
}
