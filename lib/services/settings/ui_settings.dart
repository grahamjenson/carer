import 'package:carer/models/constants.dart';
import 'package:carer/sql/key_value_store.dart';
import 'package:carer/utils/futures.dart';
import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';

enum _UINames {
  screenActive,
  uiLayoutVertical,
  uiLayoutHorizontal,
  uiTheme,
  alarmTheme,
  nightTheme,
  nightStartTime,
  nightEndTime,
  unit,
}

class UISettings {
  static final UISettings _singleton = UISettings._();
  factory UISettings() => _singleton;

  final Map<_UINames, Signal> _signals = {
    _UINames.screenActive: Signal<bool>(false, debugLabel: 'screenActive'),
    _UINames.uiLayoutVertical: Signal<UILayout>(UILayout.showBGL, debugLabel: 'uiLayoutVertical'),
    _UINames.uiLayoutHorizontal: Signal<UILayout>(UILayout.showBGL, debugLabel: 'uiLayoutHorizontal'),
    _UINames.uiTheme: Signal<UITheme>(UITheme.normal, debugLabel: 'uiTheme'),
    _UINames.alarmTheme: Signal<UITheme>(UITheme.normal, debugLabel: 'alarmTheme'),
    _UINames.nightTheme: Signal<UITheme>(UITheme.normal, debugLabel: 'nightTheme'),
    _UINames.nightStartTime: Signal<TimeOfDay>(const TimeOfDay(hour: 22, minute: 0), debugLabel: 'nightStartTime'),
    _UINames.nightEndTime: Signal<TimeOfDay>(const TimeOfDay(hour: 6, minute: 0), debugLabel: 'nightEndTime'),
    _UINames.unit: Signal<Unit>(Unit.mg, debugLabel: 'unit'),
  };

  UISettings._();

  bool get screenActive => _signals[_UINames.screenActive]!.value as bool;
  set screenActive(bool value) => _signals[_UINames.screenActive]!.value = value;

  UILayout get uiLayoutVertical => _signals[_UINames.uiLayoutVertical]!.value as UILayout;
  set uiLayoutVertical(UILayout value) => _signals[_UINames.uiLayoutVertical]!.value = value;

  UILayout get uiLayoutHorizontal => _signals[_UINames.uiLayoutHorizontal]!.value as UILayout;
  set uiLayoutHorizontal(UILayout value) => _signals[_UINames.uiLayoutHorizontal]!.value = value;

  Signal<UITheme> get uiThemeSignal => _signals[_UINames.uiTheme]! as Signal<UITheme>;
  UITheme get uiTheme => uiThemeSignal.value;
  set uiTheme(UITheme value) => uiThemeSignal.value = value;

  Signal<UITheme> get alarmThemeSignal => _signals[_UINames.alarmTheme]! as Signal<UITheme>;
  UITheme get alarmTheme => alarmThemeSignal.value;
  set alarmTheme(UITheme value) => alarmThemeSignal.value = value;

  Signal<UITheme> get nightThemeSignal => _signals[_UINames.nightTheme]! as Signal<UITheme>;
  UITheme get nightTheme => nightThemeSignal.value;
  set nightTheme(UITheme value) => nightThemeSignal.value = value;

  Signal<TimeOfDay> get nightStartTimeSignal => _signals[_UINames.nightStartTime]! as Signal<TimeOfDay>;
  TimeOfDay get nightStartTime => nightStartTimeSignal.value;
  set nightStartTime(TimeOfDay value) {
    if (tODtoInt(value) < tODtoInt(nightEndTime)) {
      return;
    }
    nightStartTimeSignal.value = value;
  }

  Signal<TimeOfDay> get nightEndTimeSignal => _signals[_UINames.nightEndTime]! as Signal<TimeOfDay>;
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

    uiLayoutVertical = UILayout.fromString(prefs.getString(_UINames.uiLayoutVertical.name));

    uiLayoutHorizontal = UILayout.fromString(prefs.getString(_UINames.uiLayoutHorizontal.name));

    uiTheme = UITheme.fromString(prefs.getString(_UINames.uiTheme.name));

    alarmTheme = UITheme.fromString(prefs.getString(_UINames.alarmTheme.name));

    nightTheme = UITheme.fromString(prefs.getString(_UINames.nightTheme.name));

    nightStartTime = tODfromInt(prefs.getInt(_UINames.nightStartTime.name, defaultValue: 22 * 60)!);

    nightEndTime = tODfromInt(prefs.getInt(_UINames.nightEndTime.name, defaultValue: 6 * 60)!);

    unit = Unit.fromBool(prefs.getBool(_UINames.unit.name, defaultValue: true)!);

    // Setup DB sync for when signalls change

    aeffect(() => prefs.setBool(_UINames.unit.name, unit.toBool()));

    aeffect(() {
      prefs.setBool(_UINames.screenActive.name, screenActive);
    });

    aeffect(() {
      prefs.setString(_UINames.uiLayoutVertical.name, uiLayoutVertical.name);
    });

    aeffect(() {
      prefs.setString(_UINames.uiLayoutHorizontal.name, uiLayoutHorizontal.name);
    });

    aeffect(() {
      prefs.setString(_UINames.uiTheme.name, uiTheme.name);
    });

    aeffect(() {
      prefs.setString(_UINames.alarmTheme.name, alarmTheme.name);
    });

    aeffect(() {
      prefs.setString(_UINames.nightTheme.name, nightTheme.name);
    });

    aeffect(() {
      prefs.setInt(_UINames.nightStartTime.name, tODtoInt(nightStartTime));
    });

    aeffect(() {
      prefs.setInt(_UINames.nightEndTime.name, tODtoInt(nightEndTime));
    });
  }
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
  showBGL("BGL");

  final String viewName;

  const UILayout(this.viewName);

  static UILayout fromString(String? value) {
    return UILayout.values.firstWhere((e) => e.name == value, orElse: () => UILayout.showBGL);
  }
}
