import 'dart:async';

import 'package:carer/mappers/sql/logs/snooze_log.dart';
import 'package:carer/sql/key_value_store.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/utils/logs.dart';
import 'package:clock/clock.dart';

enum _AANames {
  // Predictions
  smartSnoozeHigh,

  // AUDIO SETTINGS
  enableAudioAlarm,
  volumeOveride,
  volumeOverrideValue,
  volumeProgressionSeconds,
  alarmAsset,

  // Other ALARM
  enableFlashOnAlarm,
  brightnessAdjustAtNight,
  enableAutoSnoozeOff,

  // ephemeral
  snoozeUntil,
}

enum SnoozeReason {
  buttonPressed,
  buttonMissed,
  timerExpired,
  autoRemoved,
  noButtonPressed,
  unknown,
}

class AlarmAlertSettings {
  static final AlarmAlertSettings _singleton = AlarmAlertSettings._();
  factory AlarmAlertSettings() => _singleton;

  final Map<_AANames, ASignal> _signals = {
    _AANames.smartSnoozeHigh: ASignal<bool>(true, debugLabel: 'smartSnoozeHigh'),
    _AANames.brightnessAdjustAtNight: ASignal<bool>(true, debugLabel: 'brightnessAdjustAtNight'),
    _AANames.enableFlashOnAlarm: ASignal<bool>(true, debugLabel: 'enableFlashOnAlarm'),
    _AANames.enableAutoSnoozeOff: ASignal<bool>(true, debugLabel: 'enableAutoSnoozeOff'),
    _AANames.enableAudioAlarm: ASignal<bool>(true, debugLabel: 'enableAudioAlarm'),
    _AANames.volumeOveride: ASignal<bool>(true, debugLabel: 'volumeOveride'),
    _AANames.volumeOverrideValue: ASignal<int>(50, debugLabel: 'volumeOverrideValue'),
    _AANames.volumeProgressionSeconds: ASignal<int>(10, debugLabel: 'volumeProgressionSeconds'),
    _AANames.alarmAsset: ASignal<AlarmSounds>(AlarmSounds.nightguard, debugLabel: 'alarmAsset'),
    _AANames.snoozeUntil: ASignal<DateTime?>(null, debugLabel: "snoozeUntil"),
  };

  AlarmAlertSettings._();

  bool get smartSnoozeHigh => _signals[_AANames.smartSnoozeHigh]!.value as bool;
  set smartSnoozeHigh(bool value) => _signals[_AANames.smartSnoozeHigh]!.value = value;

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

  bool get enableFlashOnAlarm => _signals[_AANames.enableFlashOnAlarm]!.value as bool;
  set enableFlashOnAlarm(bool value) => _signals[_AANames.enableFlashOnAlarm]!.value = value;

  bool get enableAutoSnoozeOff => _signals[_AANames.enableAutoSnoozeOff]!.value as bool;
  set enableAutoSnoozeOff(bool value) => _signals[_AANames.enableAutoSnoozeOff]!.value = value;

  ASignal<DateTime?> get snoozeUntilSignal => _signals[_AANames.snoozeUntil]! as ASignal<DateTime?>;

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
    smartSnoozeHigh = prefs.getBool(_AANames.smartSnoozeHigh.name, defaultValue: true)!;

    enableAudioAlarm = prefs.getBool(_AANames.enableAudioAlarm.name, defaultValue: true)!;
    volumeOveride = prefs.getBool(_AANames.volumeOveride.name, defaultValue: true)!;
    volumeOverrideValue = prefs.getInt(_AANames.volumeOverrideValue.name, defaultValue: 50)!;
    volumeProgressionSeconds = prefs.getInt(_AANames.volumeProgressionSeconds.name, defaultValue: 10)!;

    var prefsAlarmAsset = prefs.getString(_AANames.alarmAsset.name, defaultValue: AlarmSounds.nightguard.name)!;
    alarmAsset = AlarmSounds.fromName(prefsAlarmAsset, AlarmSounds.nightguard);

    brightnessAdjustAtNight = prefs.getBool(_AANames.brightnessAdjustAtNight.name, defaultValue: true)!;
    enableFlashOnAlarm = prefs.getBool(_AANames.enableFlashOnAlarm.name, defaultValue: true)!;
    enableAutoSnoozeOff = prefs.getBool(_AANames.enableAutoSnoozeOff.name, defaultValue: true)!;

    aeffect(() => prefs.setBool(_AANames.smartSnoozeHigh.name, smartSnoozeHigh), debugLabel: 'smartSnoozeHigh');

    aeffect(() => prefs.setBool(_AANames.enableAudioAlarm.name, enableAudioAlarm), debugLabel: 'enableAudioAlarm');

    aeffect(() => prefs.setBool(_AANames.volumeOveride.name, volumeOveride), debugLabel: 'volumeOveride');

    aeffect(() => prefs.setInt(_AANames.volumeOverrideValue.name, volumeOverrideValue), debugLabel: 'volumeOverrideValue');

    aeffect(() => prefs.setInt(_AANames.volumeProgressionSeconds.name, volumeProgressionSeconds), debugLabel: 'volumeProgressionSeconds');

    aeffect(() {
      var value = (alarmAsset).name;
      prefs.setString(_AANames.alarmAsset.name, value);
    }, debugLabel: 'alarmAsset');

    aeffect(() {
      prefs.setBool(_AANames.brightnessAdjustAtNight.name, brightnessAdjustAtNight);
    }, debugLabel: 'brightnessAdjustAtNight');

    aeffect(() {
      prefs.setBool(_AANames.enableFlashOnAlarm.name, enableFlashOnAlarm);
    }, debugLabel: 'enableFlashOnAlarm');

    aeffect(() {
      prefs.setBool(_AANames.enableAutoSnoozeOff.name, enableAutoSnoozeOff);
    }, debugLabel: 'enableAutoSnoozeOff');
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
      SQLToSnoozeLogs().endSnooze(reason);
      snoozeUntilSignal.value = null;
      return;
    }

    snoozeTimer = Timer(Duration(seconds: value), () {
      alog("Snooze: Duration Seconds set to null from ${snoozeUntilSignal.peek()} because timer expired");
      SQLToSnoozeLogs().endSnooze(SnoozeReason.timerExpired);
      snoozeUntilSignal.value = null;
    });

    var duration = Duration(seconds: value);
    var time = clock.now().add(duration);
    alog("Snooze: Duration Seconds set to $time from ${snoozeUntilSignal.peek()} because $reason");
    SQLToSnoozeLogs().startSnooze(duration, reason);
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

  String snoozeString() {
    if (!isSnoozing()) {
      return "";
    }
    var duration = AlarmAlertSettings().snoozeDuration!;
    var minutes = duration.inMinutes;
    var hours = duration.inHours;

    if (hours > 0) {
      return "${hours}h";
    }

    if (minutes > 0) {
      return "${minutes}m";
    }

    return "<1m";
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
