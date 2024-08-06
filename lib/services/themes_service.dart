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

  Signal<ThemeData> themeSignal = Signal(dayTheme, debugLabel: "Theme");

  ThemeService._internal() {
    signalAssign(themeSignal, () async {
      if (UISettings().isNightModeActive()) {
        return nightTheme;
      } else {
        return dayTheme;
      }
    }, dependencies: [
      TimerService().minuteSignal,
      UISettings().uiThemeSignal,
      UISettings().nightThemeSignal,
      UISettings().nightStartTimeSignal,
      UISettings().nightEndTimeSignal,
    ]);
  }

  ThemeData get theme => themeSignal.value;
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

  TextStyle getHeadingTextStyle(BuildContext? context) {
    return TextStyle(
      fontWeight: FontWeight.bold,
      color: primaryColor(context),
      fontSize: 10,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  TextStyle getRowTextStyle(BuildContext? context) {
    return TextStyle(
      color: primaryColor(context),
      fontSize: 20,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  TextStyle getSmallTextStyle(BuildContext? context) {
    return TextStyle(
      color: primaryColor(context),
      fontSize: 10,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  TextStyle getSuperscriptTextStyle(BuildContext? context) {
    return TextStyle(
      color: primaryColor(context),
      fontSize: 20,
      fontWeight: FontWeight.w100,
      fontFeatures: const [FontFeature.superscripts(), FontFeature.tabularFigures()],
    );
  }
}

ThemeData dayTheme = ThemeData(
  useMaterial3: true,

  // Define the default brightness and colors.
  colorScheme: ColorScheme(
    brightness: Brightness.dark,
    primary: _primaryColor,
    onPrimary: Colors.black,
    secondary: _primaryColor.withAlpha(40),
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
    primary: _primaryColor,
    onPrimary: Colors.black,
    secondary: _primaryColor.withAlpha(40),
    onSecondary: Colors.black,
    error: Colors.black,
    onError: _primaryColor,
    surface: Colors.black,
    onSurface: _primaryColor,
  ),
);

// TODO make this proper
class Colours {
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
