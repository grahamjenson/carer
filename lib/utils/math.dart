enum Range { veryLow, low, inRange, high, veryHigh }

// find where in the target range and by what proportion a number is
// returns a tuple of (Targets, proportion)

(Range, double) range(
    double veryLow, double low, double high, double veryHigh, double value) {
  if (value < veryLow) {
    return (Range.veryLow, (veryLow - value).abs().toDouble());
  } else if (value < low) {
    return (Range.low, (low - value) / (low - veryLow));
  } else if (value < high) {
    return (Range.inRange, (high - value) / (high - low));
  } else if (value < veryHigh) {
    return (Range.high, (veryHigh - value) / (veryHigh - high));
  } else {
    return (Range.veryHigh, (value - veryHigh).abs().toDouble());
  }
}
