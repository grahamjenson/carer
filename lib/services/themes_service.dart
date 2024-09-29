import 'package:carer/models/clean_sgv.dart';
import 'package:carer/services/alarms_service.dart';
import 'package:carer/services/settings/time_settings.dart';
import 'package:carer/services/settings/ui_settings.dart';
import 'package:carer/services/timer_service.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/utils/math.dart';
import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';

class ColorPair {
  final Color day;
  final Color night;

  ColorPair(
    this.day,
    this.night,
  );
}

// Try and define all colors at this point, as a means of centralizing the color scheme
ColorPair backgroundColorConst = ColorPair(Colors.grey[850]!, Colors.black);
ColorPair textColorConst = ColorPair(const Color(0xFFEEEEEE), const Color(0xFF555555));
ColorPair widgetBackgroundColorConst = ColorPair(const Color(0xFF555555), const Color(0xFFEEEEEE));

Color blueColorConst = const Color(0xFF00BAEF);
Color redColorConst = const Color.fromARGB(255, 227, 63, 63);
Color yellowColorConst = const Color(0xFFFFCD36);

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

  Color surfaceColorDim(BuildContext context) {
    return Theme.of(context).colorScheme.surface.dim;
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

  Color outlineColor(BuildContext context) {
    return Theme.of(context).colorScheme.outline;
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
      return tertiaryColor(context);
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
      return tertiaryColor(context);
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
    return tertiaryColor(context);
  }
}

var defaultTextTheme = Typography.material2018().white;
ThemeData normalTheme = ThemeData(
  useMaterial3: true,
  textTheme: defaultTextTheme.merge(TextTheme(
    displayLarge: TextStyle(
      fontWeight: FontWeight.bold,
      color: textColorConst.day,
    ),
    displayMedium: TextStyle(
      fontWeight: FontWeight.bold,
      color: textColorConst.day,
    ),
    displaySmall: TextStyle(
      fontWeight: FontWeight.bold,
      color: textColorConst.day,
    ),
    headlineLarge: TextStyle(
      fontWeight: FontWeight.bold,
      color: textColorConst.day,
    ),
    headlineMedium: TextStyle(
      fontWeight: FontWeight.bold,
      color: textColorConst.day,
    ),
    headlineSmall: TextStyle(
      fontWeight: FontWeight.bold,
      color: textColorConst.day,
    ),
    titleLarge: TextStyle(
      fontWeight: FontWeight.bold,
      color: textColorConst.day,
    ),
    titleMedium: TextStyle(
      fontWeight: FontWeight.bold,
      color: textColorConst.day,
    ),
    titleSmall: TextStyle(
      fontWeight: FontWeight.bold,
      color: textColorConst.day,
    ),
    bodyLarge: TextStyle(
      color: textColorConst.day,
    ),
    bodyMedium: TextStyle(
      color: textColorConst.day,
    ),
    bodySmall: TextStyle(
      color: textColorConst.day,
    ),
    labelLarge: TextStyle(
      color: textColorConst.day,
    ),
    labelMedium: TextStyle(
      color: textColorConst.day,
    ),
    labelSmall: TextStyle(
      color: textColorConst.day,
    ),
  )),
  colorScheme: ColorScheme(
    brightness: Brightness.dark,
    primary: blueColorConst,
    onPrimary: Colors.white,
    secondary: redColorConst,
    onSecondary: Colors.white,
    tertiary: yellowColorConst,
    onTertiary: Colors.white,
    error: Colors.red,
    onError: Colors.white,
    surface: backgroundColorConst.day,
    onSurface: textColorConst.day,
    outline: blueColorConst.dim,
  ),
);

ThemeData dimTheme = normalTheme.copyWith(
  textTheme: normalTheme.textTheme.merge(TextTheme(
    displayLarge: TextStyle(
      fontWeight: FontWeight.w600,
      color: textColorConst.night,
    ),
    displayMedium: TextStyle(
      fontWeight: FontWeight.w600,
      color: textColorConst.night,
    ),
    displaySmall: TextStyle(
      fontWeight: FontWeight.w600,
      color: textColorConst.night,
    ),
    headlineLarge: TextStyle(
      fontWeight: FontWeight.w500,
      color: textColorConst.night,
    ),
    headlineMedium: TextStyle(
      fontWeight: FontWeight.w500,
      color: textColorConst.night,
    ),
    headlineSmall: TextStyle(
      fontWeight: FontWeight.w500,
      color: textColorConst.night,
    ),
    titleLarge: TextStyle(
      fontWeight: FontWeight.w400,
      color: textColorConst.night,
    ),
    titleMedium: TextStyle(
      fontWeight: FontWeight.w400,
      color: textColorConst.night,
    ),
    titleSmall: TextStyle(
      fontWeight: FontWeight.w400,
      color: textColorConst.night,
    ),
    bodyLarge: TextStyle(
      color: textColorConst.night,
    ),
    bodyMedium: TextStyle(
      color: textColorConst.night,
    ),
    bodySmall: TextStyle(
      color: textColorConst.night,
    ),
    labelLarge: TextStyle(
      color: textColorConst.night,
    ),
    labelMedium: TextStyle(
      color: textColorConst.night,
    ),
    labelSmall: TextStyle(
      color: textColorConst.night,
    ),
  )),
  colorScheme: ColorScheme(
    brightness: Brightness.dark,
    primary: textColorConst.night,
    onPrimary: Colors.black,
    secondary: textColorConst.night,
    onSecondary: Colors.black,
    tertiary: textColorConst.night,
    onTertiary: Colors.black,
    error: Colors.red,
    onError: Colors.white,
    surface: backgroundColorConst.night,
    onSurface: Colors.white,
    outline: Colors.black,
  ),
);

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
