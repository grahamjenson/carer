import 'dart:math';

import 'package:carer/change_notifiers/settings/target_settings.dart';

enum Range5 { veryLow, low, mid, high, veryHigh }

enum Range7 { veryVeryLow, veryLow, low, mid, high, veryHigh, veryVeryHigh }

// find where in the target range and by what proportion a number is
// returns a tuple of (Targets, proportion)
(Range5, double) targetRange(int sgv) {
  var low = TargetSettings.targetLow.value.toDouble();
  var high = TargetSettings.targetHigh.value.toDouble();
  var veryHigh = TargetSettings.urgentHigh.value.toDouble();
  var veryLow = TargetSettings.urgentLow.value.toDouble();

  return range5(veryLow, low, high, veryHigh, sgv.toDouble());
}

(Range7, double) diffRange(int fastDrop, int fastRise, int diff) {
  // This is bases on percentage of the current sgv because the closer to low the more important it is
  return range7(fastDrop.toDouble(), fastDrop / 2, fastDrop / 3, fastRise / 3,
      fastRise / 2, fastRise.toDouble(), diff.toDouble());
}

(Range5, double) range5(
    double veryLow, double low, double high, double veryHigh, double value) {
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

(Range7, double) range7(double veryVeryLow, double veryLow, double low,
    double high, double veryHigh, double veryVeryHigh, double value) {
  if (value < veryVeryLow) {
    return (Range7.veryVeryLow, (veryVeryLow - value).abs().toDouble());
  } else if (value < veryLow) {
    return (Range7.veryLow, (veryLow - value) / (veryLow - veryVeryLow));
  } else if (value < low) {
    return (Range7.low, (low - value) / (low - veryLow));
  } else if (value < high) {
    return (Range7.mid, (high - value) / (high - low));
  } else if (value < veryHigh) {
    return (Range7.high, (veryHigh - value) / (veryHigh - high));
  } else if (value < veryVeryHigh) {
    return (
      Range7.veryHigh,
      (veryVeryHigh - value) / (veryVeryHigh - veryHigh)
    );
  } else {
    return (Range7.veryVeryHigh, (value - veryVeryHigh).abs().toDouble());
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
  static double rootMeanSquaredError(
      List<double> xValues, List<double> yValues, List<double> predictions) {
    assert(
        xValues.length == yValues.length &&
            xValues.length == predictions.length,
        'x should have the same length as y');

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
