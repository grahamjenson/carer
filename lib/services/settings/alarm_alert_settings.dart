import 'dart:async';

import 'package:carer/sql/key_value_store.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/utils/logs.dart';
import 'package:clock/clock.dart';

enum _AANames {
  // Predictions
  smartSnoozeHigh,

  // AUDIO SETTINGS
  volumeOveride,
  volumeOverrideValue,
  volumeProgressionSeconds,
  alarmAsset,

  // Other ALARM
  brightnessAdjustAtNight,

  // ephemeral
  sleepUntil,
}

class AlarmAlertSettings {
  static final AlarmAlertSettings _singleton = AlarmAlertSettings._();
  factory AlarmAlertSettings() => _singleton;

  final Map<_AANames, ASignal> _signals = {
    _AANames.smartSnoozeHigh: ASignal<bool>(false, debugLabel: 'smartSnoozeHigh'),
    _AANames.brightnessAdjustAtNight: ASignal<bool>(false, debugLabel: 'brightnessAdjustAtNight'),
    _AANames.volumeOveride: ASignal<bool>(false, debugLabel: 'volumeOveride'),
    _AANames.volumeOverrideValue: ASignal<int>(10, debugLabel: 'volumeOverrideValue'),
    _AANames.volumeProgressionSeconds: ASignal<int>(10, debugLabel: 'volumeProgressionSeconds'),
    _AANames.alarmAsset: ASignal<AlarmSounds>(AlarmSounds.nightguard, debugLabel: 'alarmAsset'),
    _AANames.sleepUntil: ASignal<DateTime?>(null, debugLabel: "sleepUntil"),
  };

  AlarmAlertSettings._();

  bool get smartSnoozeHigh => _signals[_AANames.smartSnoozeHigh]!.value as bool;
  set smartSnoozeHigh(bool value) => _signals[_AANames.smartSnoozeHigh]!.value = value;

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

  ASignal<DateTime?> get sleepUntilSignal => _signals[_AANames.sleepUntil]! as ASignal<DateTime?>;

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
    smartSnoozeHigh = prefs.getBool(_AANames.smartSnoozeHigh.name, defaultValue: false)!;
    volumeOveride = prefs.getBool(_AANames.volumeOveride.name, defaultValue: false)!;
    volumeOverrideValue = prefs.getInt(_AANames.volumeOverrideValue.name, defaultValue: 50)!;
    volumeProgressionSeconds = prefs.getInt(_AANames.volumeProgressionSeconds.name, defaultValue: 10)!;

    var prefsAlarmAsset = prefs.getString(_AANames.alarmAsset.name, defaultValue: AlarmSounds.nightguard.name)!;
    alarmAsset = AlarmSounds.values.firstWhere((e) => e.name == prefsAlarmAsset, orElse: () => AlarmSounds.nightguard);

    brightnessAdjustAtNight = prefs.getBool(_AANames.brightnessAdjustAtNight.name, defaultValue: false)!;

    aeffect(() => prefs.setBool(_AANames.smartSnoozeHigh.name, smartSnoozeHigh), debugLabel: 'smartSnoozeHigh');

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
  }

  Timer? sleepTimer;
  Duration? get sleepDuration {
    return _calculateSleepDuration(sleepUntilSignal.value);
  }

  Duration? get sleepDurationPeek {
    return _calculateSleepDuration(sleepUntilSignal.peek());
  }

  Duration? _calculateSleepDuration(DateTime? sleepUntil) {
    if (sleepUntil == null) {
      return null;
    }
    var duration = sleepUntil.difference(clock.now());

    if (duration.isNegative) {
      return null;
    }

    return duration;
  }

  int? get sleepDurationSeconds {
    return sleepDuration?.inSeconds;
  }

  void setSleepDurationSeconds(int? value, String reason) {
    if (sleepTimer != null) {
      sleepTimer!.cancel(); // Always cancel
    }

    if (value == null) {
      alog("Alarm: Sleep: Sleep Duration Seconds set to null from ${sleepUntilSignal.peek} because $reason");
      sleepUntilSignal.value = null;
      return;
    }

    sleepTimer = Timer(Duration(seconds: value), () {
      alog("Alarm: Sleep: Sleep Duration Seconds set to null from ${sleepUntilSignal.peek} because timer expired");
      sleepUntilSignal.value = null;
    });

    var time = clock.now().add(Duration(seconds: value));
    alog("Alarm: Sleep: Sleep Duration Seconds set to $time from ${sleepUntilSignal.peek}");
    sleepUntilSignal.value = time;
  }
}

enum AlarmSounds { nightguard, letsgo, hybridas }

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
