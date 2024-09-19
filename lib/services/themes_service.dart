import 'package:carer/services/alarms_service.dart';
import 'package:carer/services/settings/time_settings.dart';
import 'package:carer/services/settings/ui_settings.dart';
import 'package:carer/services/timer_service.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/utils/math.dart';
import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';

class ThemeService {
  static final ThemeService _themeService = ThemeService._internal();
  factory ThemeService() {
    return _themeService;
  }

  ASignal<ThemeData> themeSignal = ASignal(normalTheme, debugLabel: "Theme");
  late ValueNotifier<ThemeData> themeNotifier;

  ThemeService._internal() {
    themeNotifier = themeSignal.toValueNotifier();

    signalAssign(
      themeSignal,
      selectTheme,
      debugLabel: "ThemeSignalAssign",
      dependencies: [
            TimerService().minuteSignal,
            AlarmsService().activeAlarms,
          ] +
          UISettings().allSignals,
    );
  }

  ThemeData get theme => themeSignal.value;

  static ThemeData selectTheme() {
    if (AlarmsService().activeAlarms.value.isNotEmpty) {
      return normalTheme;
    }

    if (TimeSettings().isNight() && UISettings().enableDim) {
      return dimTheme;
    } else {
      return normalTheme;
    }
  }
}

Color _primaryColor = const Color.fromARGB(255, 199, 210, 172);

mixin ThemeMixin {
  Color primaryColor(BuildContext context) {
    return Theme.of(context).colorScheme.primary;
  }

  Color secondaryColor(BuildContext context) {
    return Theme.of(context).colorScheme.secondary;
  }

  TextStyle getSuperscriptTextStyle() {
    return const TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w100,
      fontFeatures: [FontFeature.superscripts(), FontFeature.tabularFigures()],
    );
  }

  TextStyle textStyleWithShadows() {
    return const TextStyle(shadows: [
      Shadow(
          // bottomLeft
          offset: Offset(-1, -1),
          color: Colors.black),
      Shadow(
          // bottomRight
          offset: Offset(1, -1),
          color: Colors.black),
      Shadow(
          // topRight
          offset: Offset(1, 1),
          color: Colors.black),
      Shadow(
          // topLeft
          offset: Offset(-1, 1),
          color: Colors.black),
    ]);
  }
}

const TextStyle defaultTextStyle = TextStyle(
  fontSize: 20,
  fontWeight: FontWeight.w500,
  fontFeatures: [FontFeature.tabularFigures()],
  color: Colors.purple,
);

ThemeData normalTheme = ThemeData(
  useMaterial3: true,

  textTheme: const TextTheme(
    displayLarge: defaultTextStyle,
    displayMedium: defaultTextStyle,
    displaySmall: defaultTextStyle,
    headlineLarge: defaultTextStyle,
    headlineMedium: defaultTextStyle,
    //headlineSmall: defaultTextStyle,
    //titleLarge: defaultTextStyle,
    //titleMedium: defaultTextStyle,
    //titleSmall: defaultTextStyle,
    //bodyLarge: defaultTextStyle,
    bodyMedium: defaultTextStyle,
    bodySmall: defaultTextStyle,
    labelLarge: defaultTextStyle,
    labelMedium: defaultTextStyle,
    labelSmall: defaultTextStyle,
  ),

  // Define the default brightness and colors.
  colorScheme: ColorScheme(
    brightness: Brightness.dark,
    primary: Colors.purple,
    onPrimary: Colors.black,
    secondary: Colors.purple,
    onSecondary: Colors.black,
    tertiary: Colors.purple,
    onTertiary: Colors.black,
    error: Colors.red,
    onError: _primaryColor,
    surface: Colors.black,
    onSurface: _primaryColor,
  ),
);

ThemeData dimTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme(
    brightness: Brightness.dark,
    primary: Colors.purple,
    onPrimary: Colors.black,
    secondary: _primaryColor.dim.dim.dim,
    onSecondary: Colors.black,
    error: Colors.red,
    onError: _primaryColor,
    surface: Colors.black,
    onSurface: _primaryColor.dim.dim,
  ),
);

// TODO make this proper
class AColors {
  static Color targetColor(Range5 target, num proportion) {
    var color1 = const Color.fromARGB(255, 169, 131, 129);
    var color2 = const Color.fromARGB(255, 107, 129, 108);

    switch (target) {
      case Range5.veryLow:
        color1 = const Color.fromARGB(255, 202, 175, 173);
        color2 = const Color.fromARGB(255, 193, 153, 151);
      case Range5.low:
        color1 = const Color.fromARGB(255, 160, 157, 124);
        color2 = const Color.fromARGB(255, 144, 113, 110);
      case Range5.mid:
        color1 = const Color.fromARGB(255, 117, 150, 118);
        color2 = const Color.fromARGB(255, 139, 186, 140);
      case Range5.high:
        color1 = Colors.red;
        color2 = Colors.yellow;
      case Range5.veryHigh:
        color1 = const Color.fromARGB(255, 133, 111, 110);
        color2 = const Color.fromARGB(255, 155, 126, 124);
    }

    return Color.lerp(color1, color2, proportion.toDouble()) ?? Colors.red;
  }

  static Color diffColour(Range5 target, num proportion) {
    var color1 = Colors.red;
    var color2 = Colors.green;

    switch (target) {
      case Range5.veryLow:
        color1 = Colors.red;
        color2 = Colors.red;
      case Range5.low:
        color1 = Colors.yellow;
        color2 = Colors.red;
      case Range5.mid:
        color1 = Colors.grey;
        color2 = Colors.grey;
      case Range5.high:
        color1 = Colors.red;
        color2 = Colors.yellow;
      case Range5.veryHigh:
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

extension ColorExtension on Color {
  Color get dim {
    var amount = 0.7;
    return Color.fromARGB(
      alpha,
      (red * amount).round(),
      (green * amount).round(),
      (blue * amount).round(),
    );
  }
}
