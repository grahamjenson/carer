import 'package:carer/models/settings_cn.dart';

enum Range5 { veryLow, low, mid, high, veryHigh }

enum Range7 { veryVeryLow, veryLow, low, mid, high, veryHigh, veryVeryHigh }

// find where in the target range and by what proportion a number is
// returns a tuple of (Targets, proportion)

(Range5, double) targetRange(Settings settings, int sgv) {
  var low = settings.targetLow.toDouble();
  var high = settings.targetHigh.toDouble();
  var veryHigh = settings.urgentHigh.toDouble();
  var veryLow = settings.urgentLow.toDouble();

  return range5(veryLow, low, high, veryHigh, sgv.toDouble());
}

(Range7, double) diffRange(int currentsgv, int diff) {
  // This is bases on percentage of the current sgv because the closer to low the more important it is
  return range7(-0.15, -0.07, -0.05, 0.05, 0.07, 0.15, diff / currentsgv);
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
