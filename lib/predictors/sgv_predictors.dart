import 'package:carer/models/clean_sgv.dart';
import 'package:carer/predictors/regressions.dart';
import 'package:carer/utils/math.dart';
import 'package:clock/clock.dart';

abstract class Predictor {
  Predictor();

  // set this to get the cadence of sgv predictinos correct
  final DateTime _lastReadingDate = clock.now();

  // Get all the expencive calls done here, and can be repedtly called when new data arrives
  init({required List<CleanSGV?> lastSGVs});

  // Returns the predicted value at mins
  CleanSGV? predictAt(double timestamp);

  DateTime get lastReadingDate => _lastReadingDate;

  // Returns all predicted values until mins
  List<CleanSGV> predictRange(List<double> timestamp) {
    List<CleanSGV> predictions = [];
    for (var ts in timestamp) {
      var p = predictAt(ts);
      if (p != null) {
        predictions.add(p);
      }
    }
    return predictions;
  }

  List<CleanSGV> predictNextHour() {
    var times = List.generate(60, (i) => lastReadingDate.add(Duration(minutes: (i + 1))).millisecondsSinceEpoch.toDouble());

    return predictRange(times);
  }

  CleanSGV? predictNext() {
    var time = lastReadingDate.add(const Duration(minutes: 5)).millisecondsSinceEpoch.toDouble();

    return predictAt(time);
  }

  CleanSGV? predictMin(int mins) {
    var time = lastReadingDate.add(Duration(minutes: mins)).millisecondsSinceEpoch.toDouble();

    return predictAt(time);
  }

  Future<double> rmse(List<double> futureX, List<double> futureY) async {
    var sgvs = predictRange(futureX);
    var predictions = sgvs.map((s) => s.value * 1.0).toList();
    return Math.rootMeanSquaredError(futureX, futureY, predictions);
  }
}

abstract class RegressionPredictor extends Predictor {
  Regression createRegression(List<double> x, List<double> y);

  final double mimnutesFromEpochToLastWeek = clock.now().subtract(const Duration(days: 7)).millisecondsSinceEpoch / 60000;

  int get pastReadings => 2;

  RegressionPredictor();

  late Regression regression;
  // When processing very large numbers, by squaring and cubing this can cause lots of issues
  // These functions drop x from milliseconds since epoch to
  double fnX(num x) => (x / 60000.0).round().toDouble() - mimnutesFromEpochToLastWeek;
  int fnRX(double x) => (x * 60000.0).toInt() + mimnutesFromEpochToLastWeek.toInt();

  @override
  init({required List<CleanSGV?> lastSGVs}) {
    if (lastSGVs.length < pastReadings) {
      regression = NoopRegression();
      return;
    }
    lastSGVs = lastSGVs.sublist(0, pastReadings);

    List<CleanSGV> sgvs = [];
    for (var s in lastSGVs) {
      if (s == null) {
        return NoopRegression();
      }
      sgvs.add(s);
    }

    if (sgvs.length < pastReadings) {
      regression = NoopRegression();
      return;
    }
    sgvs = sgvs.sublist(0, pastReadings);

    if (sgvs.isEmpty) {
      regression = NoopRegression();
      return;
    }

    var x = sgvs.map((s) => fnX(s.date.millisecondsSinceEpoch)).toList();
    var y = sgvs.map((s) => s.value * 1.0).toList();

    regression = createRegression(x, y);
  }

  @override
  CleanSGV? predictAt(double timestamp) {
    var pred = regression.predict(fnX(timestamp));
    if (pred.isNaN || pred.isInfinite) {
      return CleanSGV(0, DateTime.fromMillisecondsSinceEpoch(timestamp.toInt()));
    }
    int limitedValue = pred.toInt().clamp(20, 500);
    return CleanSGV(limitedValue, DateTime.fromMillisecondsSinceEpoch(timestamp.toInt()));
  }
}

class Exp2Predictor extends RegressionPredictor {
  Exp2Predictor() : super();

  @override
  int get pastReadings => 2;

  @override
  Regression createRegression(List<double> x, List<double> y) {
    return ExpRegression(x, y);
  }

  @override
  String toString() => 'LinearRegression';
}
