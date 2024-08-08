import 'package:carer/services/alarms_service.dart';
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

  Signal<ThemeData> themeSignal = Signal(normalTheme, debugLabel: "Theme");
  late ValueNotifier<ThemeData> themeNotifier;

  UIThemeLayout getCurrentThemeLayout() {
    if (AlarmsService().activeAlarms.value.isNotEmpty && UISettings().alarmUIThemeLayout.enabled) {
      return UISettings().alarmUIThemeLayout;
    } else if (UISettings().isNightModeActive() && UISettings().nightUIThemeLayout.enabled) {
      return UISettings().nightUIThemeLayout;
    } else {
      return UISettings().mainUIThemeLayout;
    }
  }

  ThemeService._internal() {
    themeNotifier = themeSignal.toValueNotifier();

    signalAssign(
      themeSignal,
      () {
        UIThemeLayout themeLayout = getCurrentThemeLayout();
        return selectTheme(themeLayout.theme);
      },
      dependencies: [
            TimerService().minuteSignal,
            UISettings().nightStartTimeSignal,
            UISettings().nightEndTimeSignal,
            AlarmsService().activeAlarms,
          ] +
          UISettings().themeLayoutSignals,
    );
  }

  ThemeData get theme => themeSignal.value;

  static ThemeData selectTheme(UITheme uitheme) {
    switch (uitheme) {
      case UITheme.normal:
        return normalTheme;
      case UITheme.dim:
        return nightTheme;
    }
  }
}

Color _primaryColor = const Color.fromARGB(255, 199, 210, 172);

mixin ThemeMixin {
  Color primaryColor(BuildContext? context) {
    if (context == null) {
      return _primaryColor;
    }
    return Theme.of(context).colorScheme.primary;
  }

  Color secondaryColor(BuildContext? context) {
    if (context == null) {
      return _primaryColor;
    }
    return Theme.of(context).colorScheme.secondary;
  }

  TextStyle getHeadingTextStyle() {
    return const TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 10,
      fontFeatures: [FontFeature.tabularFigures()],
    );
  }

  TextStyle getRowTextStyle() {
    return const TextStyle(
      fontSize: 20,
      fontFeatures: [FontFeature.tabularFigures()],
    );
  }

  TextStyle getSmallTextStyle() {
    return const TextStyle(
      fontSize: 10,
      fontFeatures: [FontFeature.tabularFigures()],
    );
  }

  TextStyle getSuperscriptTextStyle() {
    return const TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w100,
      fontFeatures: [FontFeature.superscripts(), FontFeature.tabularFigures()],
    );
  }
}

ThemeData normalTheme = ThemeData(
  useMaterial3: true,

  // Define the default brightness and colors.
  colorScheme: ColorScheme(
    brightness: Brightness.dark,
    primary: _primaryColor,
    onPrimary: _primaryColor,
    secondary: _primaryColor.dim.dim,
    onSecondary: Colors.black,
    error: Colors.black,
    onError: _primaryColor,
    surface: Colors.black,
    onSurface: _primaryColor,
  ),
);

ThemeData nightTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme(
    brightness: Brightness.dark,
    primary: _primaryColor.dim.dim,
    onPrimary: Colors.black,
    secondary: _primaryColor.dim.dim.dim,
    onSecondary: Colors.black,
    error: Colors.black,
    onError: _primaryColor,
    surface: Colors.black,
    onSurface: _primaryColor,
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
    var amount = 0.6;
    return Color.fromARGB(
      alpha,
      (red * amount).round(),
      (green * amount).round(),
      (blue * amount).round(),
    );
  }
}
