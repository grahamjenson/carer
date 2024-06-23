import 'package:carer/change_notifiers/settings_cn.dart';
import 'package:carer/sql/key_value_store.dart';
import 'package:signals/signals_flutter.dart';

enum AlarmSettings {
  disableAlarms,
  testAlarmPlaying,
  alarmAsset,

  urgentLowAlarm,
  lowAlarm,
  lowMinutes,
  highAlarm,
  highMinutes,
  urgentHighAlarm,

  fastDropAlarm,
  fastDropAlarmMinutes,
  fastDropDelta,

  fastRiseAlarm,
  fastRiseAlarmMinutes,
  fastRiseDelta,

  noDataAlarmMinutes,

  lowPredictionAlarm,
  lowPredictionMinutes,
  smartSnooze,

  volumeOveride,
  volumeOverrideValue,
  volumeProgressionSeconds;

  Signal get _signal {
    return _settingsSignals[this]!;
  }

  set value(dynamic value) {
    switch (this) {
      case AlarmSettings.lowMinutes ||
            AlarmSettings.highMinutes ||
            AlarmSettings.lowPredictionMinutes ||
            AlarmSettings.fastDropAlarmMinutes ||
            AlarmSettings.fastRiseAlarmMinutes:
        var validValues = [0, 5, 10, 15, 20, 30, 45, 60];
        if (!validValues.contains(value)) {
          return;
        }
        break;
      case AlarmSettings.noDataAlarmMinutes:
        var validValues = [-1, 10, 20, 30];
        if (!validValues.contains(value)) {
          return;
        }
        break;
      case AlarmSettings.volumeOverrideValue:
        if (value < 0) {
          value = 0;
        } else if (value > 100) {
          value = 100;
        }
        break;
      case AlarmSettings.volumeProgressionSeconds:
        var validValues = [-1, 10, 20, 30, 60, 120];
        if (!validValues.contains(value)) {
          return;
        }
        break;
      case AlarmSettings.fastDropDelta:
        if (value > 8) {
          value = 8;
        }
        break;
      case AlarmSettings.fastRiseDelta:
        if (value < -8) {
          value = -8;
        }
        break;
      default:
        break;
    }
    _settingsSignals[this]!.value = value;
  }

  get value {
    return _settingsSignals[this]!.value;
  }

  dynamic get peek {
    return _settingsSignals[this]!.peek();
  }
}

Map<AlarmSettings, Signal> _settingsSignals = {};

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

class AlarmSettingsCN {
  KeyValueStore prefs;
  SettingsCN settings;

  // ephemeral properters

  AlarmSettingsCN({required this.prefs, required this.settings}) {
    _settingsSignals = {
      AlarmSettings.disableAlarms: Signal<bool>(_disableAlarms),
      AlarmSettings.urgentLowAlarm: Signal<bool>(_urgentLowAlarm),
      AlarmSettings.lowAlarm: Signal<bool>(_lowAlarm),
      AlarmSettings.lowMinutes: Signal<int>(_lowMinutes),
      AlarmSettings.highAlarm: Signal<bool>(_highAlarm),
      AlarmSettings.highMinutes: Signal<int>(_highMinutes),
      AlarmSettings.urgentHighAlarm: Signal<bool>(_urgentHighAlarm),
      AlarmSettings.fastDropAlarm: Signal<bool>(_fastDropAlarm),
      AlarmSettings.fastDropAlarmMinutes: Signal<int>(_fastDropAlarmMinutes),
      AlarmSettings.fastDropDelta: Signal<int>(_fastDropDelta),
      AlarmSettings.fastRiseAlarm: Signal<bool>(_fastRiseAlarm),
      AlarmSettings.fastRiseAlarmMinutes: Signal<int>(_fastRiseAlarmMinutes),
      AlarmSettings.fastRiseDelta: Signal<int>(_fastRiseDelta),
      AlarmSettings.noDataAlarmMinutes: Signal<int>(_noDataAlarmMinutes),
      AlarmSettings.lowPredictionAlarm: Signal<bool>(_lowPredictionAlarm),
      AlarmSettings.lowPredictionMinutes: Signal<int>(_lowPredictionMinutes),
      AlarmSettings.smartSnooze: Signal<bool>(_smartSnooze),
      AlarmSettings.volumeOveride: Signal<bool>(_volumeOveride),
      AlarmSettings.volumeOverrideValue: Signal<int>(_volumeOverrideValue),
      AlarmSettings.volumeProgressionSeconds:
          Signal<int>(_volumeProgressionSeconds),
      AlarmSettings.testAlarmPlaying: Signal<bool>(false),
      AlarmSettings.alarmAsset: Signal<AlarmSounds>(_alarmAsset),
    };

    effect(() => prefs.setBool(
        AlarmSettings.disableAlarms.name, AlarmSettings.disableAlarms.value));

    effect(() => prefs.setBool(
        AlarmSettings.urgentLowAlarm.name, AlarmSettings.urgentLowAlarm.value));

    effect(() => prefs.setBool(
        AlarmSettings.lowAlarm.name, AlarmSettings.lowAlarm.value));

    effect(() => prefs.setInt(
        AlarmSettings.lowMinutes.name, AlarmSettings.lowMinutes.value));

    effect(() => prefs.setBool(
        AlarmSettings.highAlarm.name, AlarmSettings.highAlarm.value));

    effect(() => prefs.setInt(
        AlarmSettings.highMinutes.name, AlarmSettings.highMinutes.value));

    effect(() => prefs.setBool(AlarmSettings.urgentHighAlarm.name,
        AlarmSettings.urgentHighAlarm.value));

    effect(() => prefs.setBool(
        AlarmSettings.fastDropAlarm.name, AlarmSettings.fastDropAlarm.value));

    effect(() => prefs.setInt(AlarmSettings.fastDropAlarmMinutes.name,
        AlarmSettings.fastDropAlarmMinutes.value));

    effect(() => prefs.setInt(
        AlarmSettings.fastDropDelta.name, AlarmSettings.fastDropDelta.value));

    effect(() => prefs.setBool(
        AlarmSettings.fastRiseAlarm.name, AlarmSettings.fastRiseAlarm.value));

    effect(() => prefs.setInt(AlarmSettings.fastRiseAlarmMinutes.name,
        AlarmSettings.fastRiseAlarmMinutes.value));

    effect(() => prefs.setInt(
        AlarmSettings.fastRiseDelta.name, AlarmSettings.fastRiseDelta.value));

    effect(() => prefs.setInt(AlarmSettings.noDataAlarmMinutes.name,
        AlarmSettings.noDataAlarmMinutes.value));

    effect(() => prefs.setBool(AlarmSettings.lowPredictionAlarm.name,
        AlarmSettings.lowPredictionAlarm.value));

    effect(() => prefs.setInt(AlarmSettings.lowPredictionMinutes.name,
        AlarmSettings.lowPredictionMinutes.value));

    effect(() => prefs.setBool(
        AlarmSettings.smartSnooze.name, AlarmSettings.smartSnooze.value));

    effect(() => prefs.setBool(
        AlarmSettings.volumeOveride.name, AlarmSettings.volumeOveride.value));

    effect(() => prefs.setInt(AlarmSettings.volumeOverrideValue.name,
        AlarmSettings.volumeOverrideValue.value));

    effect(() => prefs.setInt(AlarmSettings.volumeProgressionSeconds.name,
        AlarmSettings.volumeProgressionSeconds.value));

    effect(() {
      var value = (AlarmSettings.alarmAsset.value as AlarmSounds).name;
      prefs.setString(AlarmSettings.alarmAsset.name, value);
    });
  }

  bool get _disableAlarms =>
      prefs.getBool(AlarmSettings.disableAlarms.name, defaultValue: false)!;

  bool get _urgentLowAlarm =>
      prefs.getBool(AlarmSettings.urgentLowAlarm.name, defaultValue: false)!;

  bool get _lowAlarm =>
      prefs.getBool(AlarmSettings.lowAlarm.name, defaultValue: false)!;

  bool get _highAlarm =>
      prefs.getBool(AlarmSettings.highAlarm.name, defaultValue: false)!;

  int get _lowMinutes =>
      prefs.getInt(AlarmSettings.lowMinutes.name, defaultValue: 30)!;

  int get _highMinutes =>
      prefs.getInt(AlarmSettings.highMinutes.name, defaultValue: 30)!;

  bool get _urgentHighAlarm =>
      prefs.getBool(AlarmSettings.urgentHighAlarm.name, defaultValue: false)!;

  bool get _lowPredictionAlarm => prefs
      .getBool(AlarmSettings.lowPredictionAlarm.name, defaultValue: false)!;

  int get _lowPredictionMinutes =>
      prefs.getInt(AlarmSettings.lowPredictionMinutes.name, defaultValue: 30)!;

  bool get _fastDropAlarm =>
      prefs.getBool(AlarmSettings.fastDropAlarm.name, defaultValue: false)!;

  int get _fastDropAlarmMinutes =>
      prefs.getInt(AlarmSettings.fastDropAlarmMinutes.name, defaultValue: 30)!;

  int get _fastDropDelta =>
      prefs.getInt(AlarmSettings.fastDropDelta.name, defaultValue: -20)!;

  bool get _fastRiseAlarm =>
      prefs.getBool(AlarmSettings.fastRiseAlarm.name, defaultValue: false)!;

  int get _fastRiseAlarmMinutes =>
      prefs.getInt(AlarmSettings.fastRiseAlarmMinutes.name, defaultValue: 30)!;

  int get _fastRiseDelta =>
      prefs.getInt(AlarmSettings.fastRiseDelta.name, defaultValue: 20)!;

  int get _noDataAlarmMinutes =>
      prefs.getInt(AlarmSettings.noDataAlarmMinutes.name, defaultValue: 30)!;

  bool get _smartSnooze =>
      prefs.getBool(AlarmSettings.smartSnooze.name, defaultValue: false)!;

  bool get _volumeOveride =>
      prefs.getBool(AlarmSettings.volumeOveride.name, defaultValue: false)!;

  int get _volumeOverrideValue =>
      prefs.getInt(AlarmSettings.volumeOverrideValue.name, defaultValue: 50)!;

  int get _volumeProgressionSeconds => prefs
      .getInt(AlarmSettings.volumeProgressionSeconds.name, defaultValue: 10)!;

  AlarmSounds get _alarmAsset {
    var asset = prefs.getString('alarmAsset', defaultValue: 'Nightguard');
    return AlarmSounds.values.firstWhere((e) => e.name == asset,
        orElse: () => AlarmSounds.nightguard);
  }
}
