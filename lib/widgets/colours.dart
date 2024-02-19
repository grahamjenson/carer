import 'dart:ui';

import 'package:carer/utils/math.dart';
import 'package:flutter/material.dart';

class Colours {
  static Color targetColor(Range target, num proportion) {
    var color1 = Colors.red;
    var color2 = Colors.green;

    switch (target) {
      case Range.veryLow:
        color1 = Colors.red;
        color2 = Colors.red;
      case Range.low:
        color1 = Colors.yellow;
        color2 = Colors.red;
      case Range.inRange:
        color1 = Colors.green;
        color2 = Colors.green;
      case Range.high:
        color1 = Colors.red;
        color2 = Colors.yellow;
      case Range.veryHigh:
        color1 = Colors.red;
        color2 = Colors.red;
    }

    return Color.lerp(color1, color2, proportion.toDouble()) ?? Colors.red;
  }

  static Color diffColour(Range target, num proportion) {
    var color1 = Colors.red;
    var color2 = Colors.green;

    switch (target) {
      case Range.veryLow:
        color1 = Colors.red;
        color2 = Colors.red;
      case Range.low:
        color1 = Colors.yellow;
        color2 = Colors.red;
      case Range.inRange:
        color1 = Colors.grey;
        color2 = Colors.grey;
      case Range.high:
        color1 = Colors.red;
        color2 = Colors.yellow;
      case Range.veryHigh:
        color1 = Colors.red;
        color2 = Colors.red;
    }

    return Color.lerp(color1, color2, proportion.toDouble()) ?? Colors.red;
  }

  static Color timeSinceLastReading(Duration age) {
    var color = Colors.grey;
    if (age.inMinutes > 6) {
      color = Colors.red;
    }
    return color;
  }
}
