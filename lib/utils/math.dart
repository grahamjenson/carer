import 'dart:math';

import 'package:carer/services/settings/target_settings.dart';

enum Range5 { veryLow, low, mid, high, veryHigh }

// find where in the target range and by what proportion a number is
// returns a tuple of (Targets, proportion)
(Range5, double) targetRange(num sgv) {
  var low = TargetSettings().lowTarget.toDouble();
  var high = TargetSettings().highTarget.toDouble();
  var veryHigh = TargetSettings().highUrgent.toDouble();
  var veryLow = TargetSettings().lowUrgent.toDouble();

  return range5(veryLow, low, high, veryHigh, sgv);
}

Range5 diffRange5(num diff) {
  var (dr, _) = diffRange(
    TargetSettings().fastDropDelta,
    TargetSettings().fastRiseDelta,
    diff,
  );

  return dr;
}

(Range5, double) diffRange(num fastDrop, num fastRise, num diff) {
  return range5(fastDrop, fastDrop * 0.8, fastRise * 0.8, fastRise, diff.toDouble());
}

(Range5, double) range5(num veryLow, num low, num high, num veryHigh, num value) {
  if (value < veryLow) {
    return (Range5.veryLow, (veryLow - value).abs().toDouble());
  } else if (value < low) {
    return (Range5.low, (low - value) / (low - veryLow));
  } else if (value < high) {
    return (Range5.mid, (high - value) / (high - low));
  } else if (value < veryHigh) {
    return (Range5.high, (veryHigh - value) / (veryHigh - high));
  } else {
    return (Range5.veryHigh, (value - veryHigh).abs().toDouble());
  }
}

// functino that returns double at most 2dp
double toMax2dp(num value) {
  return (value * 100.0).round() / 100.0;
}

int mean(List<int> l) {
  return (l.reduce((a, b) => a + b) / l.length).round();
}

class Math {
  static double rootMeanSquaredError(List<double> xValues, List<double> yValues, List<double> predictions) {
    assert(xValues.length == yValues.length && xValues.length == predictions.length, 'x should have the same length as y');

    int count = xValues.length;

    var errors = [];
    for (int index = 0; index < count; index++) {
      var yVal = yValues[index];
      var prediction = predictions[index];
      var error = prediction - yVal;
      errors.add(pow(error, 2));
    }

    // root mean squared error = sqrt(sum of squared errors / count)
    // https://en.wikipedia.org/wiki/Root-mean-square_deviation
    var rmse = sqrt(errors.reduce((a, b) => a + b) / count);

    return rmse;
  }
}
