import 'dart:ui';

import 'package:carer/utils/math.dart';
import 'package:flutter/material.dart';

class Colours {
  static Color targetColor(Range target, num proportion) {
    var color1 = const Color.fromARGB(255, 169, 131, 129);
    var color2 = const Color.fromARGB(255, 107, 129, 108);

    switch (target) {
      case Range.veryLow:
        color1 = const Color.fromARGB(255, 202, 175, 173);
        color2 = const Color.fromARGB(255, 193, 153, 151);
      case Range.low:
        color1 = const Color.fromARGB(255, 160, 157, 124);
        color2 = const Color.fromARGB(255, 144, 113, 110);
      case Range.inRange:
        color1 = const Color.fromARGB(255, 117, 150, 118);
        color2 = const Color.fromARGB(255, 139, 186, 140);
      case Range.high:
        color1 = Colors.red;
        color2 = Colors.yellow;
      case Range.veryHigh:
        color1 = const Color.fromARGB(255, 133, 111, 110);
        color2 = const Color.fromARGB(255, 155, 126, 124);
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
