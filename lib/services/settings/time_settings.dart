import 'package:carer/sql/key_value_store.dart';
import 'package:carer/utils/futures.dart';
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';

enum _TimeSettingsNames {
  nightStartTime,
  nightEndTime,

  // Ephemeral
  nightModeUntil
}

class TimeSettings {
  static final TimeSettings _singleton = TimeSettings._();
  factory TimeSettings() => _singleton;

  final Map<_TimeSettingsNames, ASignal> _signals = {
    _TimeSettingsNames.nightStartTime: ASignal<TimeOfDay>(const TimeOfDay(hour: 22, minute: 0), debugLabel: 'nightStartTime'),
    _TimeSettingsNames.nightEndTime: ASignal<TimeOfDay>(const TimeOfDay(hour: 6, minute: 0), debugLabel: 'nightEndTime'),
    _TimeSettingsNames.nightModeUntil: ASignal<DateTime?>(null, debugLabel: "nightModeUntil"),
  };

  int tODtoInt(TimeOfDay myTime) => myTime.hour * 60 + myTime.minute;
  TimeOfDay tODfromInt(int myTime) => TimeOfDay(hour: myTime ~/ 60, minute: myTime % 60);

  bool isNight() {
    final now = tODtoInt(TimeOfDay.now());

    if (isNightModeOverride()) {
      return true;
    }

    var start = tODtoInt(nightStartTime);
    var end = tODtoInt(nightEndTime);

    // start is always greater than end, e.g. 22:00 > 06:00.
    return start < end ? now >= start && now < end : now >= start || now < end;
  }

  TimeSettings._();

  ASignal<TimeOfDay> get nightStartTimeSignal => _signals[_TimeSettingsNames.nightStartTime]! as ASignal<TimeOfDay>;
  TimeOfDay get nightStartTime => nightStartTimeSignal.value;
  set nightStartTime(TimeOfDay value) {
    if (tODtoInt(value) < tODtoInt(nightEndTime)) {
      return;
    }
    nightStartTimeSignal.value = value;
  }

  ASignal<TimeOfDay> get nightEndTimeSignal => _signals[_TimeSettingsNames.nightEndTime]! as ASignal<TimeOfDay>;
  TimeOfDay get nightEndTime => nightEndTimeSignal.value;
  set nightEndTime(TimeOfDay value) {
    if (tODtoInt(value) > tODtoInt(nightStartTime)) {
      return;
    }
    nightEndTimeSignal.value = value;
  }

  ASignal<DateTime?> get nightModeUntilSignal => _signals[_TimeSettingsNames.nightModeUntil]! as ASignal<DateTime?>;

  setupDBPropagation(KeyValueStore prefs) {
    // Assign the values from the DB

    nightStartTime = tODfromInt(prefs.getInt(_TimeSettingsNames.nightStartTime.name, defaultValue: 22 * 60)!);

    nightEndTime = tODfromInt(prefs.getInt(_TimeSettingsNames.nightEndTime.name, defaultValue: 6 * 60)!);

    aeffect(() {
      prefs.setInt(_TimeSettingsNames.nightStartTime.name, tODtoInt(nightStartTime));
    }, debugLabel: _TimeSettingsNames.nightStartTime.name);

    aeffect(() {
      prefs.setInt(_TimeSettingsNames.nightEndTime.name, tODtoInt(nightEndTime));
    }, debugLabel: _TimeSettingsNames.nightEndTime.name);
  }

  bool isNightModeOverride() {
    if (nightModeUntilSignal.value == null) {
      return false;
    }

    if (nightModeUntilSignal.value!.isBefore(clock.now())) {
      nightModeUntilSignal.value = null;
      return false;
    }

    return true;
  }

  void stopNightModeOverride() {
    nightModeUntilSignal.value = null;
  }

  void nightModeOverride() {
    // Set night mode to true until the TimeOfDay of end, which may be tomorrow
    nightModeUntilSignal.value = clock.now().add(const Duration(hours: 8));
  }
}
