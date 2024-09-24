import 'package:carer/sql/key_value_store.dart';
import 'package:carer/utils/futures.dart';
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';

enum _TimeSettingsNames {
  nightSunsetTime,
  nightSunriseTime,

  // Ephemeral
  nightModeOverride
}

class NightModeOverride {
  bool isNightOverride;
  DateTime until;
  NightModeOverride(this.isNightOverride, this.until);

  bool get isDayOverride => !isNightOverride;
}

class TimeSettings {
  static final TimeSettings _singleton = TimeSettings._();
  factory TimeSettings() => _singleton;

  final Map<_TimeSettingsNames, ASignal> _signals = {
    _TimeSettingsNames.nightSunsetTime: ASignal<TimeOfDay>(const TimeOfDay(hour: 22, minute: 0), debugLabel: 'nightSunsetTime'),
    _TimeSettingsNames.nightSunriseTime: ASignal<TimeOfDay>(const TimeOfDay(hour: 6, minute: 0), debugLabel: 'nightSunriseTime'),
    _TimeSettingsNames.nightModeOverride: ASignal<NightModeOverride?>(null, debugLabel: "nightModeOverride"),
  };

  int tODtoInt(TimeOfDay myTime) => myTime.hour * 60 + myTime.minute;
  TimeOfDay tODfromInt(int myTime) => TimeOfDay(hour: myTime ~/ 60, minute: myTime % 60);

  bool isNightModeOverride() {
    var override = nightModeOverrideSignal.value;
    if (override == null) {
      return false;
    }
    if (!override.isNightOverride) {
      return false;
    }

    return clock.now().isBefore(override.until);
  }

  bool isDayModeOverride() {
    var override = nightModeOverrideSignal.value;
    if (override == null) {
      return false;
    }
    if (!override.isDayOverride) {
      return false;
    }
    return clock.now().isBefore(override.until);
  }

  bool isNight({withOverrides = true}) {
    if (withOverrides) {
      if (isNightModeOverride()) {
        return true;
      }

      if (isDayModeOverride()) {
        return false;
      }
    }

    final now = tODtoInt(TimeOfDay.now());

    var start = tODtoInt(nightSunsetTime);
    var end = tODtoInt(nightSunriseTime);

    // start is always greater than end, e.g. 22:00 > 06:00.
    return start < end ? now >= start && now < end : now >= start || now < end;
  }

  bool isDay({withOverrides = true}) {
    return !isNight(withOverrides: withOverrides);
  }

  TimeSettings._();

  ASignal<TimeOfDay> get nightSunsetTimeSignal => _signals[_TimeSettingsNames.nightSunsetTime]! as ASignal<TimeOfDay>;
  TimeOfDay get nightSunsetTime => nightSunsetTimeSignal.value;
  set nightSunsetTime(TimeOfDay value) {
    if (tODtoInt(value) < tODtoInt(nightSunriseTime)) {
      return;
    }
    nightSunsetTimeSignal.value = value;
  }

  ASignal<TimeOfDay> get nightSunriseTimeSignal => _signals[_TimeSettingsNames.nightSunriseTime]! as ASignal<TimeOfDay>;
  TimeOfDay get nightSunriseTime => nightSunriseTimeSignal.value;
  set nightSunriseTime(TimeOfDay value) {
    if (tODtoInt(value) > tODtoInt(nightSunsetTime)) {
      return;
    }
    nightSunriseTimeSignal.value = value;
  }

  ASignal<NightModeOverride?> get nightModeOverrideSignal => _signals[_TimeSettingsNames.nightModeOverride]! as ASignal<NightModeOverride?>;

  setupDBPropagation(KeyValueStore prefs) {
    // Assign the values from the DB

    nightSunsetTime = tODfromInt(prefs.getInt(_TimeSettingsNames.nightSunsetTime.name, defaultValue: 22 * 60)!);

    nightSunriseTime = tODfromInt(prefs.getInt(_TimeSettingsNames.nightSunriseTime.name, defaultValue: 6 * 60)!);

    aeffect(() {
      prefs.setInt(_TimeSettingsNames.nightSunsetTime.name, tODtoInt(nightSunsetTime));
    }, debugLabel: _TimeSettingsNames.nightSunsetTime.name);

    aeffect(() {
      prefs.setInt(_TimeSettingsNames.nightSunriseTime.name, tODtoInt(nightSunriseTime));
    }, debugLabel: _TimeSettingsNames.nightSunriseTime.name);
  }

  void removeNightOverride() {
    nightModeOverrideSignal.value = null;
  }

  void nightModeOverride() {
    // Set night mode until sunrise the next day
    var tod = nightSunriseTime;
    var now = clock.now();
    var nextTime = DateTime(now.year, now.month, now.day, tod.hour, tod.minute);
    if (nextTime.isBefore(now)) {
      nextTime = nextTime.add(const Duration(days: 1));
    }

    nightModeOverrideSignal.value = NightModeOverride(true, nextTime);
  }

  void dayModeOverride() {
    // Set day mode until sunset the next day
    var tod = nightSunsetTime;
    var now = clock.now();
    var nextTime = DateTime(now.year, now.month, now.day, tod.hour, tod.minute);
    if (nextTime.isBefore(now)) {
      nextTime = nextTime.add(const Duration(days: 1));
    }

    nightModeOverrideSignal.value = NightModeOverride(false, nextTime);
  }
}
