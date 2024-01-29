enum TargetRange { veryLow, low, inRange, high, veryHigh }

// find where in the target range and by what proportion a number is
// returns a tuple of (Targets, proportion)

(TargetRange, num) targetRange(
    double veryLow, double low, double high, double veryHigh, double value) {
  if (value < veryLow) {
    return (TargetRange.veryLow, (veryLow - value).abs());
  } else if (value < low) {
    return (TargetRange.low, (low - value) / (low - veryLow));
  } else if (value < high) {
    return (TargetRange.inRange, (high - value) / (high - low));
  } else if (value < veryHigh) {
    return (TargetRange.high, (veryHigh - value) / (veryHigh - high));
  } else {
    return (TargetRange.veryHigh, (value - veryHigh).abs());
  }
}
