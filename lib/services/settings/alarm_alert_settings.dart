import 'package:carer/sql/key_value_store.dart';
import 'package:carer/utils/futures.dart';
import 'package:signals/signals_flutter.dart';

enum _AANames {
  // Predictions
  smartSnooze,

  // AUDIO SETTINGS
  volumeOveride,
  volumeOverrideValue,
  volumeProgressionSeconds,
  alarmAsset,

  // Other ALARM
  brightnessAdjust,
}

class AlarmAlertSettings {
  static final AlarmAlertSettings _singleton = AlarmAlertSettings._();
  factory AlarmAlertSettings() => _singleton;

  final Map<_AANames, Signal> _signals = {
    _AANames.smartSnooze: Signal<bool>(false, debugLabel: 'smartSnooze'),
    _AANames.brightnessAdjust: Signal<bool>(false, debugLabel: 'brightnessAdjust'),
    _AANames.volumeOveride: Signal<bool>(false, debugLabel: 'volumeOveride'),
    _AANames.volumeOverrideValue: Signal<int>(10, debugLabel: 'volumeOverrideValue'),
    _AANames.volumeProgressionSeconds: Signal<int>(10, debugLabel: 'volumeProgressionSeconds'),
    _AANames.alarmAsset: Signal<AlarmSounds>(AlarmSounds.nightguard, debugLabel: 'alarmAsset'),
  };

  AlarmAlertSettings._();

  bool get smartSnooze => _signals[_AANames.smartSnooze]!.value as bool;
  set smartSnooze(bool value) => _signals[_AANames.smartSnooze]!.value = value;

  bool get volumeOveride => _signals[_AANames.volumeOveride]!.value as bool;
  set volumeOveride(bool value) => _signals[_AANames.volumeOveride]!.value = value;

  int get volumeOverrideValue => _signals[_AANames.volumeOverrideValue]!.value as int;
  int get volumeOverrideValuePeek => _signals[_AANames.volumeOverrideValue]!.peek() as int;

  set volumeOverrideValue(int value) => volumeOverrideValueSet(_signals[_AANames.volumeOverrideValue]! as Signal<int>, value);

  int get volumeProgressionSeconds => _signals[_AANames.volumeProgressionSeconds]!.value as int;
  set volumeProgressionSeconds(int value) => volumeProgressionSecondsSet(_signals[_AANames.volumeProgressionSeconds]! as Signal<int>, value);

  AlarmSounds get alarmAsset => _signals[_AANames.alarmAsset]!.value as AlarmSounds;
  set alarmAsset(AlarmSounds value) => _signals[_AANames.alarmAsset]!.value = value;

  bool get brightnessAdjust => _signals[_AANames.brightnessAdjust]!.value as bool;
  set brightnessAdjust(bool value) => _signals[_AANames.brightnessAdjust]!.value = value;

  allValues() {
    for (var signal in _signals.values) {
      var _ = signal.value;
    }
  }

  minutesSet(Signal<int> signal, value) {
    var validValues = [0, 5, 10, 15, 20, 30, 45, 60];
    if (!validValues.contains(value)) {
      return false;
    }
    signal.value = value;
  }

  noDataAlarmSet(Signal<int> signal, value) {
    var validValues = [-1, 10, 20, 30];
    if (!validValues.contains(value)) {
      return false;
    }
    signal.value = value;
  }

  volumeOverrideValueSet(Signal<int> signal, value) {
    if (value < 0) {
      value = 0;
    } else if (value > 100) {
      value = 100;
    }
    signal.value = value;
  }

  volumeProgressionSecondsSet(Signal<int> signal, value) {
    var validValues = [-1, 10, 20, 30, 60, 120];
    if (!validValues.contains(value)) {
      return false;
    }
    signal.value = value;
  }

  setupDBPropagation(KeyValueStore prefs) {
    smartSnooze = prefs.getBool(_AANames.smartSnooze.name, defaultValue: false)!;
    volumeOveride = prefs.getBool(_AANames.volumeOveride.name, defaultValue: false)!;
    volumeOverrideValue = prefs.getInt(_AANames.volumeOverrideValue.name, defaultValue: 50)!;
    volumeProgressionSeconds = prefs.getInt(_AANames.volumeProgressionSeconds.name, defaultValue: 10)!;

    var prefsAlarmAsset = prefs.getString(_AANames.alarmAsset.name, defaultValue: AlarmSounds.nightguard.name)!;
    alarmAsset = AlarmSounds.values.firstWhere((e) => e.name == prefsAlarmAsset, orElse: () => AlarmSounds.nightguard);

    brightnessAdjust = prefs.getBool(_AANames.brightnessAdjust.name, defaultValue: false)!;

    aeffect(() => prefs.setBool(_AANames.smartSnooze.name, smartSnooze));

    aeffect(() => prefs.setBool(_AANames.volumeOveride.name, volumeOveride));

    aeffect(() => prefs.setInt(_AANames.volumeOverrideValue.name, volumeOverrideValue));

    aeffect(() => prefs.setInt(_AANames.volumeProgressionSeconds.name, volumeProgressionSeconds));

    aeffect(() {
      var value = (alarmAsset).name;
      prefs.setString(_AANames.alarmAsset.name, value);
    });

    aeffect(() {
      prefs.setBool(_AANames.brightnessAdjust.name, brightnessAdjust);
    });
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
