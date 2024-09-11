import 'package:carer/models/constants.dart';
import 'package:carer/sql/key_value_store.dart';
import 'package:carer/utils/futures.dart';
import 'package:flutter/material.dart';

enum _UINames {
  unit,
  screenActive,
  nightStartTime,
  nightEndTime,
}

enum UITheme {
  // NS Settings
  normal("Normal"),
  dim("Dim");

  final String viewName;

  const UITheme(this.viewName);

  static UITheme fromString(String? value) {
    return UITheme.values.firstWhere((e) => e.name == value, orElse: () => UITheme.normal);
  }
}

enum UILayout {
  // NS Settings
  showBGLChartHistoryStats("Everything"),
  showBGL("BGL"),
  showMinimal("Minimal");

  final String viewName;

  const UILayout(this.viewName);

  static UILayout fromString(String? value) {
    return UILayout.values.firstWhere((e) => e.name == value, orElse: () => UILayout.showBGL);
  }
}

enum ThemeLayout {
  mainUI,
  alarmUI,
  nightUI,
}

class UIThemeLayout {
  final String baseName;
  late ASignal<UITheme> themeSignal;
  late ASignal<UILayout> horizonalLayoutSignal;
  late ASignal<UILayout> verticalLayoutSignal;
  late ASignal<bool> enabledSignal;

  UIThemeLayout(this.baseName) {
    enabledSignal = ASignal<bool>(true, debugLabel: enabledPref);
    themeSignal = ASignal<UITheme>(UITheme.normal, debugLabel: themePref);
    horizonalLayoutSignal = ASignal<UILayout>(UILayout.showBGL, debugLabel: horizonalLayoutPref);
    verticalLayoutSignal = ASignal<UILayout>(UILayout.showBGL, debugLabel: verticalLayoutPref);
  }

  List<ASignal> get signals => [enabledSignal, themeSignal, horizonalLayoutSignal, verticalLayoutSignal];

  String get enabledPref => "${baseName}Enabled";
  bool get enabled => enabledSignal.value;
  set enabled(bool value) => enabledSignal.value = value;

  String get themePref => "${baseName}Theme";
  UITheme get theme => themeSignal.value;
  set theme(UITheme value) => themeSignal.value = value;

  String get horizonalLayoutPref => "${baseName}HorizonalLayout";
  UILayout get horizonalLayout => horizonalLayoutSignal.value;
  set horizonalLayout(UILayout value) => horizonalLayoutSignal.value = value;

  String get verticalLayoutPref => "${baseName}VerticalLayout";
  UILayout get verticalLayout => verticalLayoutSignal.value;
  set verticalLayout(UILayout value) => verticalLayoutSignal.value = value;

  setup(KeyValueStore prefs) {
    enabled = prefs.getBool(enabledPref, defaultValue: true)!;
    theme = UITheme.fromString(prefs.getString(themePref));
    horizonalLayout = UILayout.fromString(prefs.getString(horizonalLayoutPref));
    verticalLayout = UILayout.fromString(prefs.getString(verticalLayoutPref));

    aeffect(() {
      prefs.setBool(enabledPref, enabled);
    });

    aeffect(() {
      prefs.setString(themePref, theme.name);
    });

    aeffect(() {
      prefs.setString(horizonalLayoutPref, horizonalLayout.name);
    });

    aeffect(() {
      prefs.setString(verticalLayoutPref, verticalLayout.name);
    });
  }
}

class UISettings {
  static final UISettings _singleton = UISettings._();
  factory UISettings() => _singleton;

  final Map<_UINames, ASignal> _signals = {
    _UINames.screenActive: ASignal<bool>(false, debugLabel: 'screenActive'),
    _UINames.nightStartTime: ASignal<TimeOfDay>(const TimeOfDay(hour: 22, minute: 0), debugLabel: 'nightStartTime'),
    _UINames.nightEndTime: ASignal<TimeOfDay>(const TimeOfDay(hour: 6, minute: 0), debugLabel: 'nightEndTime'),
    _UINames.unit: ASignal<Unit>(Unit.mg, debugLabel: 'unit'),
  };

  Map<ThemeLayout, UIThemeLayout> themeLayouts = {
    ThemeLayout.mainUI: UIThemeLayout(ThemeLayout.mainUI.name),
    ThemeLayout.alarmUI: UIThemeLayout(ThemeLayout.alarmUI.name),
    ThemeLayout.nightUI: UIThemeLayout(ThemeLayout.nightUI.name),
  };

  List<ASignal> get themeLayoutSignals => themeLayouts.values.expand((e) => e.signals).toList();
  UIThemeLayout get mainUIThemeLayout => themeLayouts[ThemeLayout.mainUI]!;
  UIThemeLayout get alarmUIThemeLayout => themeLayouts[ThemeLayout.alarmUI]!;
  UIThemeLayout get nightUIThemeLayout => themeLayouts[ThemeLayout.nightUI]!;

  UISettings._();

  bool get screenActive => _signals[_UINames.screenActive]!.value as bool;
  set screenActive(bool value) => _signals[_UINames.screenActive]!.value = value;

  ASignal<TimeOfDay> get nightStartTimeSignal => _signals[_UINames.nightStartTime]! as ASignal<TimeOfDay>;
  TimeOfDay get nightStartTime => nightStartTimeSignal.value;
  set nightStartTime(TimeOfDay value) {
    if (tODtoInt(value) < tODtoInt(nightEndTime)) {
      return;
    }
    nightStartTimeSignal.value = value;
  }

  ASignal<TimeOfDay> get nightEndTimeSignal => _signals[_UINames.nightEndTime]! as ASignal<TimeOfDay>;
  TimeOfDay get nightEndTime => nightEndTimeSignal.value;
  set nightEndTime(TimeOfDay value) {
    if (tODtoInt(value) > tODtoInt(nightStartTime)) {
      return;
    }
    nightEndTimeSignal.value = value;
  }

  Unit get unit => _signals[_UINames.unit]!.value as Unit;
  set unit(Unit value) => _signals[_UINames.unit]!.value = value;

  int tODtoInt(TimeOfDay myTime) => myTime.hour * 60 + myTime.minute;
  TimeOfDay tODfromInt(int myTime) => TimeOfDay(hour: myTime ~/ 60, minute: myTime % 60);

  bool isNightModeActive() {
    final now = tODtoInt(TimeOfDay.now());
    var start = tODtoInt(nightStartTime);
    var end = tODtoInt(nightEndTime);

    // start is always greater than end, e.g. 22:00 > 06:00.
    return start < end ? now >= start && now < end : now >= start || now < end;
  }

  setupDBPropagation(KeyValueStore prefs) {
    // Assign the values from the DB
    screenActive = prefs.getBool(_UINames.screenActive.name, defaultValue: true)!;

    nightStartTime = tODfromInt(prefs.getInt(_UINames.nightStartTime.name, defaultValue: 22 * 60)!);

    nightEndTime = tODfromInt(prefs.getInt(_UINames.nightEndTime.name, defaultValue: 6 * 60)!);

    unit = Unit.fromBool(prefs.getBool(_UINames.unit.name, defaultValue: true)!);

    for (var themeLayout in themeLayouts.values) {
      themeLayout.setup(prefs);
    }
    // Setup DB sync for when signalls change

    aeffect(() => prefs.setBool(_UINames.unit.name, unit.toBool()));

    aeffect(() {
      prefs.setBool(_UINames.screenActive.name, screenActive);
    });

    aeffect(() {
      prefs.setInt(_UINames.nightStartTime.name, tODtoInt(nightStartTime));
    });

    aeffect(() {
      prefs.setInt(_UINames.nightEndTime.name, tODtoInt(nightEndTime));
    });
  }
}
