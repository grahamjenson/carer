import 'dart:async';

import 'package:carer/models/details/alarms/alarms.dart';
import 'package:carer/models/sql/events/snooze_events.dart';
import 'package:carer/services/alarms_service.dart';
import 'package:carer/sql/key_value_store.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/utils/logs.dart';
import 'package:clock/clock.dart';

enum _AANames {
  // AUDIO SETTINGS
  enableAudioAlarm,
  volumeOveride,
  volumeOverrideValue,
  volumeProgressionSeconds,
  alarmAsset,

  // Other ALARM
  enableFlashOnAlarm,
  enableNotifications,
  brightnessAdjustAtNight,
  enableWakeUpInRange,
  enableWakeUpWhenUrgent,

  // ephemeral
  snoozeUntil,
  snoozeUntilAlarms,
  testAlarm,
}

enum SnoozeReason {
  buttonPressed,
  cancelPressed,
  buttonMissed,
  timerExpired,
  wakeUpWhenInRange,
  wakeUpWhenUrgent,
  noButtonPressed,
  unknown,
}

class AlarmAlertSettings {
  static final AlarmAlertSettings _singleton = AlarmAlertSettings._();
  factory AlarmAlertSettings() => _singleton;

  final Map<_AANames, ASignal> _signals = {
    _AANames.brightnessAdjustAtNight: ASignal<bool>(true, debugLabel: 'brightnessAdjustAtNight'),
    _AANames.enableFlashOnAlarm: ASignal<bool>(true, debugLabel: 'enableFlashOnAlarm'),
    // Smart Wake Up
    _AANames.enableWakeUpInRange: ASignal<bool>(true, debugLabel: 'enableWakeUpInRange'),
    _AANames.enableWakeUpWhenUrgent: ASignal<bool>(true, debugLabel: 'enableWakeUpWhenUrgent'),
    // Notification
    _AANames.enableNotifications: ASignal<bool>(true, debugLabel: 'enableNotifications'),
    // Audio
    _AANames.enableAudioAlarm: ASignal<bool>(true, debugLabel: 'enableAudioAlarm'),
    _AANames.volumeOveride: ASignal<bool>(true, debugLabel: 'volumeOveride'),
    _AANames.volumeOverrideValue: ASignal<int>(50, debugLabel: 'volumeOverrideValue'),
    _AANames.volumeProgressionSeconds: ASignal<int>(10, debugLabel: 'volumeProgressionSeconds'),
    _AANames.alarmAsset: ASignal<AlarmSounds>(AlarmSounds.nightguard, debugLabel: 'alarmAsset'),
    _AANames.snoozeUntil: ASignal<DateTime?>(null, debugLabel: "snoozeUntil"),
    _AANames.snoozeUntilAlarms: ASignal<AlarmSet>(AlarmSet({}), debugLabel: "snoozeUntilAlarms"),
    _AANames.testAlarm: ASignal<DateTime?>(null, debugLabel: "testAlarm"),
  };

  AlarmAlertSettings._();

  bool get enableAudioAlarm => _signals[_AANames.enableAudioAlarm]!.value as bool;
  set enableAudioAlarm(bool value) => _signals[_AANames.enableAudioAlarm]!.value = value;

  bool get volumeOveride => _signals[_AANames.volumeOveride]!.value as bool;
  set volumeOveride(bool value) => _signals[_AANames.volumeOveride]!.value = value;

  int get volumeOverrideValue => _signals[_AANames.volumeOverrideValue]!.value as int;
  int get volumeOverrideValuePeek => _signals[_AANames.volumeOverrideValue]!.peek() as int;

  set volumeOverrideValue(int value) => volumeOverrideValueSet(_signals[_AANames.volumeOverrideValue]! as ASignal<int>, value);

  int get volumeProgressionSeconds => _signals[_AANames.volumeProgressionSeconds]!.value as int;
  set volumeProgressionSeconds(int value) => volumeProgressionSecondsSet(_signals[_AANames.volumeProgressionSeconds]! as ASignal<int>, value);

  AlarmSounds get alarmAsset => _signals[_AANames.alarmAsset]!.value as AlarmSounds;
  set alarmAsset(AlarmSounds value) => _signals[_AANames.alarmAsset]!.value = value;

  bool get brightnessAdjustAtNight => _signals[_AANames.brightnessAdjustAtNight]!.value as bool;
  set brightnessAdjustAtNight(bool value) => _signals[_AANames.brightnessAdjustAtNight]!.value = value;

  bool get enableNotifications => _signals[_AANames.enableNotifications]!.value as bool;
  set enableNotifications(bool value) => _signals[_AANames.enableNotifications]!.value = value;

  bool get enableFlashOnAlarm => _signals[_AANames.enableFlashOnAlarm]!.value as bool;
  set enableFlashOnAlarm(bool value) => _signals[_AANames.enableFlashOnAlarm]!.value = value;

  bool get enableWakeUpInRange => _signals[_AANames.enableWakeUpInRange]!.value as bool;
  set enableWakeUpInRange(bool value) => _signals[_AANames.enableWakeUpInRange]!.value = value;

  bool get enableWakeUpWhenUrgent => _signals[_AANames.enableWakeUpWhenUrgent]!.value as bool;
  set enableWakeUpWhenUrgent(bool value) => _signals[_AANames.enableWakeUpWhenUrgent]!.value = value;

  ASignal<DateTime?> get snoozeUntilSignal => _signals[_AANames.snoozeUntil]! as ASignal<DateTime?>;
  ASignal<AlarmSet> get snoozeUntilSignalAlarms => _signals[_AANames.snoozeUntilAlarms]! as ASignal<AlarmSet>;

  // Test alarm will be true for 5 minutes after it is set
  bool get testAlarm {
    var testDate = _signals[_AANames.testAlarm]!.value as DateTime?;
    if (testDate == null) {
      return false;
    }
    var diff = clock.now().difference(testDate);
    if (diff.inMinutes < 2) {
      return true;
    }
    return false;
  }

  set testAlarm(bool value) {
    if (value) {
      _signals[_AANames.testAlarm]!.value = clock.now();
    } else {
      _signals[_AANames.testAlarm]!.value = null;
    }
  }

  allValues() {
    for (var signal in _signals.values) {
      var _ = signal.value;
    }
  }

  List<ASignal> allSignals() {
    return _signals.values.toList();
  }

  minutesSet(ASignal<int> signal, value) {
    var validValues = [0, 5, 10, 15, 20, 30, 45, 60];
    if (!validValues.contains(value)) {
      return false;
    }
    signal.value = value;
  }

  noDataAlarmSet(ASignal<int> signal, value) {
    var validValues = [-1, 10, 20, 30];
    if (!validValues.contains(value)) {
      return false;
    }
    signal.value = value;
  }

  volumeOverrideValueSet(ASignal<int> signal, value) {
    if (value < 0) {
      value = 0;
    } else if (value > 100) {
      value = 100;
    }
    signal.value = value;
  }

  volumeProgressionSecondsSet(ASignal<int> signal, value) {
    var validValues = [-1, 10, 20, 30, 60, 120];
    if (!validValues.contains(value)) {
      return false;
    }
    signal.value = value;
  }

  setupDBPropagation(KeyValueStore prefs) {
    enableAudioAlarm = prefs.getBool(_AANames.enableAudioAlarm.name, defaultValue: true)!;
    volumeOveride = prefs.getBool(_AANames.volumeOveride.name, defaultValue: true)!;
    volumeOverrideValue = prefs.getInt(_AANames.volumeOverrideValue.name, defaultValue: 50)!;
    volumeProgressionSeconds = prefs.getInt(_AANames.volumeProgressionSeconds.name, defaultValue: 10)!;

    var prefsAlarmAsset = prefs.getString(_AANames.alarmAsset.name, defaultValue: AlarmSounds.nightguard.name)!;
    alarmAsset = AlarmSounds.fromName(prefsAlarmAsset, AlarmSounds.nightguard);

    brightnessAdjustAtNight = prefs.getBool(_AANames.brightnessAdjustAtNight.name, defaultValue: true)!;
    enableFlashOnAlarm = prefs.getBool(_AANames.enableFlashOnAlarm.name, defaultValue: true)!;
    enableNotifications = prefs.getBool(_AANames.enableNotifications.name, defaultValue: true)!;
    enableWakeUpInRange = prefs.getBool(_AANames.enableWakeUpInRange.name, defaultValue: true)!;
    enableWakeUpWhenUrgent = prefs.getBool(_AANames.enableWakeUpWhenUrgent.name, defaultValue: true)!;

    aeffect(() => prefs.setBool(_AANames.enableAudioAlarm.name, enableAudioAlarm), debugLabel: 'writeenableAudioAlarm');

    aeffect(() => prefs.setBool(_AANames.volumeOveride.name, volumeOveride), debugLabel: 'writevolumeOveride');

    aeffect(() => prefs.setInt(_AANames.volumeOverrideValue.name, volumeOverrideValue), debugLabel: 'writevolumeOverrideValue');

    aeffect(() => prefs.setInt(_AANames.volumeProgressionSeconds.name, volumeProgressionSeconds), debugLabel: 'writevolumeProgressionSeconds');

    aeffect(() {
      var value = (alarmAsset).name;
      prefs.setString(_AANames.alarmAsset.name, value);
    }, debugLabel: 'writealarmAsset');

    aeffect(() {
      prefs.setBool(_AANames.brightnessAdjustAtNight.name, brightnessAdjustAtNight);
    }, debugLabel: 'writebrightnessAdjustAtNight');

    aeffect(() {
      prefs.setBool(_AANames.enableNotifications.name, enableNotifications);
    }, debugLabel: 'writeenableNotifications');

    aeffect(() {
      prefs.setBool(_AANames.enableFlashOnAlarm.name, enableFlashOnAlarm);
    }, debugLabel: 'writeenableFlashOnAlarm');

    aeffect(() {
      prefs.setBool(_AANames.enableWakeUpInRange.name, enableWakeUpInRange);
    }, debugLabel: 'writeenableWakeUpInRange');

    aeffect(() {
      prefs.setBool(_AANames.enableWakeUpWhenUrgent.name, enableWakeUpWhenUrgent);
    }, debugLabel: 'writeenableWakeUpWhenUrgent');
  }

  Timer? snoozeTimer;

  Duration? get snoozeDuration {
    return _calculateSnoozeDuration(snoozeUntilSignal.value);
  }

  Duration get snoozeLastSet {
    return snoozeUntilSignal.lastSetAgo;
  }

  Duration? get snoozeDurationPeek {
    return _calculateSnoozeDuration(snoozeUntilSignal.peek());
  }

  Duration? _calculateSnoozeDuration(DateTime? snoozeUntil) {
    if (snoozeUntil == null) {
      return null;
    }
    var duration = snoozeUntil.difference(clock.now());

    if (duration.isNegative) {
      return null;
    }

    return duration;
  }

  int? get snoozeDurationSeconds {
    return snoozeDuration?.inSeconds;
  }

  // THIS IS THE ONLY METHOD TO UPDATE THE SNOOZE VALUE
  void setSnoozeDurationSeconds(int? value, SnoozeReason reason) {
    if (snoozeTimer != null) {
      snoozeTimer!.cancel(); // Always cancel
    }

    if (value == null) {
      alog("Snooze: Duration Seconds set to null from ${snoozeUntilSignal.peek()} because $reason");
      SnoozeEvent.endSnooze(reason);
      snoozeUntilSignal.value = null;
      return;
    }

    snoozeTimer = Timer(Duration(seconds: value), () {
      alog("Snooze: Duration Seconds set to null from ${snoozeUntilSignal.peek()} because timer expired");
      SnoozeEvent.endSnooze(SnoozeReason.timerExpired);
      snoozeUntilSignal.value = null;
    });

    var duration = Duration(seconds: value);
    var time = clock.now().add(duration);
    alog("Snooze: Duration Seconds set to $time from ${snoozeUntilSignal.peek()} because $reason");
    SnoozeEvent.startSnooze(duration, reason);
    snoozeUntilSignalAlarms.value = AlarmsService().pendingAlarms.peek();
    snoozeUntilSignal.value = time;
  }

  bool isSnoozing() {
    var duration = AlarmAlertSettings().snoozeDuration;
    if (duration == null) {
      return false;
    }
    var totalSeconds = duration.inSeconds;
    if (totalSeconds <= 0) {
      return false;
    }
    return true;
  }

  String snoozeDurationInMinutes() {
    if (!isSnoozing()) {
      return "";
    }
    var duration = AlarmAlertSettings().snoozeDuration!;
    var minutes = duration.inMinutes;

    if (minutes > 0) {
      return "$minutes";
    }

    return "<1";
  }
}

enum AlarmSounds {
  nightguard,
  letsgo,
  hybridas;

  static AlarmSounds fromName(String name, AlarmSounds defaultValue) {
    return AlarmSounds.values.firstWhere((e) => e.name == name, orElse: () => defaultValue);
  }
}

extension AlarmSoundsExtension on AlarmSounds {
  String get name {
    switch (this) {
      case AlarmSounds.nightguard:
        return 'Nightguard';
      case AlarmSounds.letsgo:
        return 'Lets Go';
      case AlarmSounds.hybridas:
        return 'Hybridas';
      default:
        return 'Nightguard';
    }
  }

  String get asset {
    switch (this) {
      case AlarmSounds.nightguard:
        return 'alarm.mp3';
      case AlarmSounds.letsgo:
        return 'letsgo.mp3';
      case AlarmSounds.hybridas:
        return 'hybridas.mp3';
      default:
        return 'alarm.mp3';
    }
  }
}
