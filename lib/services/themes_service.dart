import 'package:carer/services/alarms_service.dart';
import 'package:carer/services/settings/time_settings.dart';
import 'package:carer/services/settings/ui_settings.dart';
import 'package:carer/services/timer_service.dart';
import 'package:carer/utils/futures.dart';
import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';

class ColorSchemes {
  // Basing the working on https://www.youtube.com/watch?v=wIuVvCuiJhU&ab_channel=Juxtopposed video
  // Created and exported from https://www.realtimecolors.com/?colors=efeeec-080705-FFCD36-ffb600-3accf8&fonts=Inter-Inter
  // Trying to use the themes from Diabetes awareness month nz logo
  static const textColor = Color(0xFFefeeec);
  static const backgroundColor = Color(0xFF323231);
  static const primaryColor = Color(0xFFFFCD36);
  static const primaryFgColor = Color(0xFF080705);
  static const secondaryColor = Color(0xFFffb600);
  static const secondaryFgColor = Color(0xFF080705);
  static const accentColor = Color(0xFF3accf8);
  static const accentFgColor = Color(0xFF080705);
  static const errorColor = Color(0xffB3261E);
  static const onErrorColor = Color(0xffFFFFFF);

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
    error: errorColor,
    onError: onErrorColor,
  );

  static var darkcolorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: colorScheme.primary.dim,
    onPrimary: colorScheme.onPrimary.dim,
    secondary: colorScheme.secondary.dim,
    onSecondary: colorScheme.onSecondary.dim,
    tertiary: colorScheme.tertiary.dim,
    onTertiary: colorScheme.onTertiary.dim,
    surface: Colors.black,
    onSurface: colorScheme.onSurface.dim,
    error: colorScheme.error.dim,
    onError: colorScheme.onError.dim,
  );
}

ThemeData normalTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorSchemes.colorScheme,
);

ThemeData dimTheme = normalTheme.copyWith(colorScheme: ColorSchemes.darkcolorScheme);

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
            TimerService().secondSignal,
            AlarmsService().alertingAlarms,
          ] +
          UISettings().allSignals,
    );
  }

  ThemeData get theme => themeSignal.value;
  static ThemeData selectTheme() {
    if (AlarmsService().alertingAlarms.value.isNotEmpty) {
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

  Color textColor(BuildContext context) {
    return onBackgroundColor(context);
  }

  Color outlineColor(BuildContext context) {
    return backgroundColor(context).bright;
  }

  ////
  // Semantic Colors
  ////
  Color badColor(BuildContext context) {
    var cs = Theme.of(context).colorScheme;
    if (cs == ColorSchemes.colorScheme) {
      return Colors.red;
    }
    return Colors.red.dim;
  }

  Color errorColor(BuildContext context) {
    return Theme.of(context).colorScheme.error;
  }

  Color onErrorColor(BuildContext context) {
    return Theme.of(context).colorScheme.onError;
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

  Color get bright {
    var amount = 1.3;
    return Color.fromARGB(
      alpha,
      (red * amount).round(),
      (green * amount).round(),
      (blue * amount).round(),
    );
  }
}
