import 'package:carer/models/clean_sgv.dart';
import 'package:carer/services/alarms_service.dart';
import 'package:carer/services/settings/time_settings.dart';
import 'package:carer/services/settings/ui_settings.dart';
import 'package:carer/services/timer_service.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/utils/math.dart';
import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';

class ColorSchemes {
  // Basing the working on https://www.youtube.com/watch?v=wIuVvCuiJhU&ab_channel=Juxtopposed video
  // Created and exported from https://www.realtimecolors.com/?colors=efeeec-080705-FFCD36-ffb600-3accf8&fonts=Inter-Inter
  // Trying to use the themes from Diabetes awareness month nz logo
  static const textColor = Color(0xFFefeeec);
  static const backgroundColor = Color(0xFF080705);
  static const primaryColor = Color(0xFFFFCD36);
  static const primaryFgColor = Color(0xFF080705);
  static const secondaryColor = Color(0xFFffb600);
  static const secondaryFgColor = Color(0xFF080705);
  static const accentColor = Color(0xFF3accf8);
  static const accentFgColor = Color(0xFF080705);

  static const colorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: primaryColor,
    onPrimary: primaryFgColor,
    secondary: secondaryColor,
    onSecondary: secondaryFgColor,
    tertiary: accentColor,
    onTertiary: accentFgColor,
    surface: backgroundColor,
    onSurface: textColor,
    error: Brightness.dark == Brightness.light ? Color(0xffB3261E) : Color(0xffF2B8B5),
    onError: Brightness.dark == Brightness.light ? Color(0xffFFFFFF) : Color(0xff601410),
  );

  // exported from https://www.realtimecolors.com/?colors=848484-000000-777676-8d8d8d-b1b1b1&fonts=Inter-Inter
  static const darktextColor = Color(0xFF848484);
  static const darkbackgroundColor = Color(0xFF000000);
  static const darkprimaryColor = Color(0xFF777676);
  static const darkprimaryFgColor = Color(0xFF000000);
  static const darksecondaryColor = Color(0xFF8d8d8d);
  static const darksecondaryFgColor = Color(0xFF000000);
  static const darkaccentColor = Color(0xFFb1b1b1);
  static const darkaccentFgColor = Color(0xFF000000);

  static const darkcolorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: darkprimaryColor,
    onPrimary: darkprimaryFgColor,
    secondary: darksecondaryColor,
    onSecondary: darksecondaryFgColor,
    tertiary: darkaccentColor,
    onTertiary: darkaccentFgColor,
    surface: darkbackgroundColor,
    onSurface: darktextColor,
    error: Brightness.dark == Brightness.light ? Color(0xffB3261E) : Color(0xffF2B8B5),
    onError: Brightness.dark == Brightness.light ? Color(0xffFFFFFF) : Color(0xff601410),
  );
}

////
// Service
////
///
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

mixin ThemeMixin {
  Color primaryColor(BuildContext context) {
    return Theme.of(context).colorScheme.primary;
  }

  Color primaryColorShade(BuildContext context) {
    return Theme.of(context).colorScheme.primary.dim;
  }

  Color onPrimaryColor(BuildContext context) {
    return Theme.of(context).colorScheme.onPrimary;
  }

  Color secondaryColor(BuildContext context) {
    return Theme.of(context).colorScheme.secondary;
  }

  Color secondaryColorShade(BuildContext context) {
    return Theme.of(context).colorScheme.secondary.dim;
  }

  Color onSecondaryColor(BuildContext context) {
    return Theme.of(context).colorScheme.onSecondary;
  }

  Color accentColor(BuildContext context) {
    return Theme.of(context).colorScheme.tertiary;
  }

  Color accentColorShade(BuildContext context) {
    return Theme.of(context).colorScheme.tertiary.dim;
  }

  Color onAccentColor(BuildContext context) {
    return Theme.of(context).colorScheme.onTertiary;
  }

  Color backgroundColor(BuildContext context) {
    return Theme.of(context).colorScheme.surface;
  }

  Color backgroundColorShade(BuildContext context) {
    return backgroundColor(context).dim;
  }

  Color onBackgroundColor(BuildContext context) {
    return Theme.of(context).colorScheme.onSurface;
  }

  Color errorColor(BuildContext context) {
    return Theme.of(context).colorScheme.error;
  }

  Color onErrorColor(BuildContext context) {
    return Theme.of(context).colorScheme.onError;
  }

  Color outlineColor(BuildContext context) {
    return backgroundColor(context).dim;
  }

  ///
  // Text Styles
  ///
  TextStyle displayLarge(BuildContext context) {
    return Theme.of(context).textTheme.displayLarge!;
  }

  TextStyle displayMedium(BuildContext context) {
    return Theme.of(context).textTheme.displayMedium!;
  }

  TextStyle displaySmall(BuildContext context) {
    return Theme.of(context).textTheme.displaySmall!;
  }

  TextStyle headlineLarge(BuildContext context) {
    return Theme.of(context).textTheme.headlineLarge!;
  }

  TextStyle headlineMedium(BuildContext context) {
    return Theme.of(context).textTheme.headlineMedium!;
  }

  TextStyle headlineSmall(BuildContext context) {
    return Theme.of(context).textTheme.headlineSmall!;
  }

  TextStyle titleLarge(BuildContext context) {
    return Theme.of(context).textTheme.titleLarge!;
  }

  TextStyle titleMedium(BuildContext context) {
    return Theme.of(context).textTheme.titleMedium!;
  }

  TextStyle titleSmall(BuildContext context) {
    return Theme.of(context).textTheme.titleSmall!;
  }

  TextStyle bodyLarge(BuildContext context) {
    return Theme.of(context).textTheme.bodyLarge!;
  }

  TextStyle bodyMedium(BuildContext context) {
    return Theme.of(context).textTheme.bodyMedium!;
  }

  TextStyle bodySmall(BuildContext context) {
    return Theme.of(context).textTheme.bodySmall!;
  }

  TextStyle labelLarge(BuildContext context) {
    return Theme.of(context).textTheme.labelLarge!;
  }

  TextStyle labelMedium(BuildContext context) {
    return Theme.of(context).textTheme.labelMedium!;
  }

  TextStyle labelSmall(BuildContext context) {
    return Theme.of(context).textTheme.labelSmall!;
  }

  TextStyle shadows({Color color = Colors.black, double width = 1}) {
    return TextStyle(shadows: [
      Shadow(
          // bottomLeft
          offset: Offset(-width, -width),
          color: color),
      Shadow(
          // bottomRight
          offset: Offset(width, -width),
          color: color),
      Shadow(
          // topRight
          offset: Offset(width, width),
          color: color),
      Shadow(
          // topLeft
          offset: Offset(-width, width),
          color: color),
    ]);
  }

  Color? rangeColor(BuildContext context) {
    var theme = Theme.of(context).colorScheme;

    CleanSGV? sgv = CleanSGV.lastSGV.value;
    if (sgv == null) {
      return theme.error;
    }
    if (sgv.isNormal) {
      return null;
    }
    if (sgv.isLow || sgv.isHigh) {
      return accentColor(context);
    }
    return secondaryColor(context);
  }

  Color? diffColor(BuildContext context) {
    var theme = Theme.of(context).colorScheme;

    CleanSGV? sgv = CleanSGV.lastSGV.value;
    if (sgv == null) {
      return theme.error;
    }
    var diffRange = sgv.diffRange;
    if (diffRange == Range7.mid) {
      return null;
    }
    if (diffRange == Range7.low || diffRange == Range7.high) {
      return accentColor(context);
    }
    return secondaryColor(context);
  }

  Color? ageColor(BuildContext context) {
    var theme = Theme.of(context).colorScheme;

    var sgv = CleanSGV.lastSGV.value;
    if (sgv == null) {
      return theme.error;
    }

    var seconds = sgv.age.inSeconds % 300;
    if (seconds < 300) {
      return null;
    }
    return accentColor(context);
  }
}

var defaultTextTheme = Typography.material2018().white;
ThemeData normalTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorSchemes.colorScheme,
);

ThemeData dimTheme = normalTheme.copyWith(colorScheme: ColorSchemes.darkcolorScheme);

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
