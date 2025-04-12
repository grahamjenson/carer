import 'package:carer/widgets/smarttext.dart';
import 'package:flutter/material.dart';

typedef OnPressedFunction = void Function();

abstract class CareModel {
  String get description;
  Icon get icon;
  SmartText get smartText;
  Color get highlightColor;

  TextStyle get smallStyle {
    return TextStyle(fontSize: 16, color: highlightColor);
  }

  TextStyle get largeStyle {
    return TextStyle(fontSize: 22, color: highlightColor, fontWeight: FontWeight.bold);
  }

  TextStyle get subSmallStyle {
    return TextStyle(fontSize: 10, color: highlightColor, fontWeight: FontWeight.bold);
  }

  TextStyle get subLargeStyle {
    return TextStyle(fontSize: 14, color: highlightColor, fontWeight: FontWeight.bold);
  }

  OnPressedFunction generateOnPressedFunction(BuildContext context);
}
