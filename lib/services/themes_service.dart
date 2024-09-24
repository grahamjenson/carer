import 'package:carer/services/alarms_service.dart';
import 'package:carer/services/settings/time_settings.dart';
import 'package:carer/services/settings/ui_settings.dart';
import 'package:carer/services/timer_service.dart';
import 'package:carer/utils/futures.dart';
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

mixin ThemeMixin {
  Color primaryColor(BuildContext context) {
    return Theme.of(context).colorScheme.primary;
  }

  Color onPrimaryColor(BuildContext context) {
    return Theme.of(context).colorScheme.onPrimary;
  }

  Color secondaryColor(BuildContext context) {
    return Theme.of(context).colorScheme.secondary;
  }

  Color onSecondaryColor(BuildContext context) {
    return Theme.of(context).colorScheme.onSecondary;
  }

  Color tertiaryColor(BuildContext context) {
    return Theme.of(context).colorScheme.tertiary;
  }

  Color onTertiaryColor(BuildContext context) {
    return Theme.of(context).colorScheme.onTertiary;
  }

  Color surfaceColor(BuildContext context) {
    return Theme.of(context).colorScheme.surface;
  }

  Color onSurfaceColor(BuildContext context) {
    return Theme.of(context).colorScheme.onSurface;
  }

  Color errorColor(BuildContext context) {
    return Theme.of(context).colorScheme.error;
  }

  Color onErrorColor(BuildContext context) {
    return Theme.of(context).colorScheme.onError;
  }

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
}

Color primaryColorConst = const Color(0xFF00BAEF);
Color secondaryColorConst = const Color(0xFF3A9A4D);
Color tertiaryColorConst = const Color(0xFFFFCD36);
Color plainTextColorConst = const Color(0xFFBBBBBB);
Color dimTextColorConst = plainTextColorConst.dim;
Color outofRangeTsextColor = Colors.red;
Color urgentRangeTextColor = Colors.red[900]!;

ThemeData normalTheme = ThemeData(
  useMaterial3: true,
  textTheme: Typography.whiteMountainView.merge(TextTheme(
    displayLarge: TextStyle(
      fontWeight: FontWeight.bold,
      color: plainTextColorConst,
    ),
    displayMedium: TextStyle(
      fontWeight: FontWeight.bold,
      color: plainTextColorConst,
    ),
    displaySmall: TextStyle(
      fontWeight: FontWeight.bold,
      color: plainTextColorConst,
    ),
    headlineLarge: TextStyle(
      fontWeight: FontWeight.bold,
      color: plainTextColorConst,
    ),
    headlineMedium: TextStyle(
      fontWeight: FontWeight.bold,
      color: plainTextColorConst,
    ),
    headlineSmall: TextStyle(
      fontWeight: FontWeight.bold,
      color: plainTextColorConst,
    ),
    titleLarge: TextStyle(
      fontWeight: FontWeight.bold,
      color: plainTextColorConst,
    ),
    titleMedium: TextStyle(
      fontWeight: FontWeight.bold,
      color: plainTextColorConst,
    ),
    titleSmall: TextStyle(
      fontWeight: FontWeight.bold,
      color: plainTextColorConst,
    ),
    bodyLarge: TextStyle(
      color: plainTextColorConst,
    ),
    bodyMedium: TextStyle(
      color: plainTextColorConst,
    ),
    bodySmall: TextStyle(
      color: plainTextColorConst,
    ),
    labelLarge: TextStyle(
      color: plainTextColorConst,
    ),
    labelMedium: TextStyle(
      color: plainTextColorConst,
    ),
    labelSmall: TextStyle(
      color: plainTextColorConst,
    ),
  )),

  // Trying to define the colour scehem based on diabetes action month colours
  colorScheme: ColorScheme(
    brightness: Brightness.dark,
    primary: primaryColorConst,
    onPrimary: Colors.white,
    secondary: secondaryColorConst,
    onSecondary: Colors.white,
    tertiary: tertiaryColorConst,
    onTertiary: Colors.white,
    error: Colors.red,
    onError: Colors.white,
    surface: Colors.grey[900]!,
    onSurface: Colors.white,
  ),
);

ThemeData dimTheme = normalTheme.copyWith(
  textTheme: normalTheme.textTheme.merge(TextTheme(
    displayLarge: TextStyle(
      fontWeight: FontWeight.w600,
      color: dimTextColorConst,
    ),
    displayMedium: TextStyle(
      fontWeight: FontWeight.w600,
      color: dimTextColorConst,
    ),
    displaySmall: TextStyle(
      fontWeight: FontWeight.w600,
      color: dimTextColorConst,
    ),
    headlineLarge: TextStyle(
      fontWeight: FontWeight.w500,
      color: dimTextColorConst,
    ),
    headlineMedium: TextStyle(
      fontWeight: FontWeight.w500,
      color: dimTextColorConst,
    ),
    headlineSmall: TextStyle(
      fontWeight: FontWeight.w500,
      color: dimTextColorConst,
    ),
    titleLarge: TextStyle(
      fontWeight: FontWeight.w400,
      color: dimTextColorConst,
    ),
    titleMedium: TextStyle(
      fontWeight: FontWeight.w400,
      color: dimTextColorConst,
    ),
    titleSmall: TextStyle(
      fontWeight: FontWeight.w400,
      color: dimTextColorConst,
    ),
    bodyLarge: TextStyle(
      color: dimTextColorConst,
    ),
    bodyMedium: TextStyle(
      color: dimTextColorConst,
    ),
    bodySmall: TextStyle(
      color: dimTextColorConst,
    ),
    labelLarge: TextStyle(
      color: dimTextColorConst,
    ),
    labelMedium: TextStyle(
      color: dimTextColorConst,
    ),
    labelSmall: TextStyle(
      color: dimTextColorConst,
    ),
  )),
  colorScheme: ColorScheme(
    brightness: Brightness.dark,
    primary: dimTextColorConst,
    onPrimary: Colors.black,
    secondary: dimTextColorConst,
    onSecondary: Colors.black,
    tertiary: dimTextColorConst,
    onTertiary: Colors.black,
    error: Colors.red,
    onError: Colors.white,
    surface: Colors.black,
    onSurface: Colors.white,
  ),
);

// TODO make this proper

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
