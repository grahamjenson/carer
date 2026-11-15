import 'package:carer/services/themes_service.dart';
import 'package:carer/widgets/smarttext.dart';
import 'package:flutter/material.dart';

typedef OnPressedFunction = void Function();

abstract class CareModel {
  String get description;
  IconData get icon;
  SmartText get smartText;
  Color get highlightColor;

  TextStyle get smallStyle {
    return const TextStyle(fontSize: 14, color: ColorSchemes.textColor);
  }

  TextStyle get largeStyle {
    return const TextStyle(fontSize: 16, color: ColorSchemes.textColor, fontWeight: FontWeight.bold);
  }

  TextStyle get subSmallStyle {
    return const TextStyle(fontSize: 8, color: ColorSchemes.textColor, fontWeight: FontWeight.bold);
  }

  TextStyle get subLargeStyle {
    return const TextStyle(fontSize: 12, color: ColorSchemes.textColor, fontWeight: FontWeight.bold);
  }

  OnPressedFunction generateOnPressedFunction(BuildContext context);
}
