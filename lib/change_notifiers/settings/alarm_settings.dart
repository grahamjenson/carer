import 'package:carer/change_notifiers/settings_cn.dart';
import 'package:carer/sql/key_value_store.dart';

enum AlarmSettingsNames {
  disableAlarms,

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
  volumeProgressionSeconds,
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

class AlarmSettings {
  KeyValueStore prefs;
  SettingsCN settings;

  // ephemeral properters
  bool _testAlarmPlaying = false;
  AlarmSettings({required this.prefs, required this.settings});

  bool get disableAlarms => prefs.getBool(AlarmSettingsNames.disableAlarms.name,
      defaultValue: false)!;

  set disableAlarms(bool value) {
    prefs.setBool(AlarmSettingsNames.disableAlarms.name, value);
    settings.notify();
  }

  ////
  // Boundary Alarms
  ////

  // urgentLowAlarm
  bool get urgentLowAlarm => prefs
      .getBool(AlarmSettingsNames.urgentLowAlarm.name, defaultValue: false)!;
  set urgentLowAlarm(bool value) {
    prefs.setBool(AlarmSettingsNames.urgentLowAlarm.name, value);
    settings.notify();
  }

  bool get lowAlarm =>
      prefs.getBool(AlarmSettingsNames.lowAlarm.name, defaultValue: false)!;
  set lowAlarm(bool value) {
    prefs.setBool(AlarmSettingsNames.lowAlarm.name, value);
    settings.notify();
  }

  // highAlarm
  bool get highAlarm =>
      prefs.getBool(AlarmSettingsNames.highAlarm.name, defaultValue: false)!;
  set highAlarm(bool value) {
    prefs.setBool(AlarmSettingsNames.highAlarm.name, value);

    settings.notify();
  }

  int get lowMinutes =>
      prefs.getInt(AlarmSettingsNames.lowMinutes.name, defaultValue: 30)!;
  set lowMinutes(int value) {
    var validValues = [0, 5, 10, 15, 20, 30, 45, 60];
    if (!validValues.contains(value)) {
      return;
    }

    prefs.setInt(AlarmSettingsNames.lowMinutes.name, value);

    settings.notify();
  }

  int get highMinutes =>
      prefs.getInt(AlarmSettingsNames.highMinutes.name, defaultValue: 30)!;
  set highMinutes(int value) {
    var validValues = [0, 5, 10, 15, 20, 30, 45, 60];
    if (!validValues.contains(value)) {
      return;
    }

    prefs.setInt(AlarmSettingsNames.highMinutes.name, value);

    settings.notify();
  }

  // urgentHighAlarm
  bool get urgentHighAlarm => prefs
      .getBool(AlarmSettingsNames.urgentHighAlarm.name, defaultValue: false)!;
  set urgentHighAlarm(bool value) {
    prefs.setBool(AlarmSettingsNames.urgentHighAlarm.name, value);
    settings.notify();
  }

  ////
  // Prediction alarms
  ////

  bool get lowPredictionAlarm =>
      prefs.getBool(AlarmSettingsNames.lowPredictionAlarm.name,
          defaultValue: false)!;
  set lowPredictionAlarm(bool value) {
    prefs.setBool(AlarmSettingsNames.lowPredictionAlarm.name, value);

    settings.notify();
  }

  int get lowPredictionMinutes => prefs
      .getInt(AlarmSettingsNames.lowPredictionMinutes.name, defaultValue: 30)!;
  set lowPredictionMinutes(int value) {
    var validValues = [5, 10, 15, 20, 30];
    if (!validValues.contains(value)) {
      return;
    }

    prefs.setInt(AlarmSettingsNames.lowPredictionMinutes.name, value);

    settings.notify();
  }

  ////
  // Diff Alarms
  ////

  // fasrDrop
  bool get fastDropAlarm => prefs.getBool(AlarmSettingsNames.fastDropAlarm.name,
      defaultValue: false)!;
  set fastDropAlarm(bool value) {
    prefs.setBool(AlarmSettingsNames.fastDropAlarm.name, value);
    settings.notify();
  }

  int get fastDropAlarmMinutes => prefs
      .getInt(AlarmSettingsNames.fastDropAlarmMinutes.name, defaultValue: 30)!;
  set fastDropAlarmMinutes(int value) {
    var validValues = [5, 10, 15, 20, 30];
    if (!validValues.contains(value)) {
      return;
    }

    prefs.setInt(AlarmSettingsNames.fastDropAlarmMinutes.name, value);

    settings.notify();
  }

  int get fastDropDelta =>
      prefs.getInt(AlarmSettingsNames.fastDropDelta.name, defaultValue: -20)!;
  set fastDropDelta(int value) {
    if (value > -8) {
      value = -8;
    }
    prefs.setInt(AlarmSettingsNames.fastDropDelta.name, value);

    settings.notify();
  }

  // fastRise
  bool get fastRiseAlarm => prefs.getBool(AlarmSettingsNames.fastRiseAlarm.name,
      defaultValue: false)!;
  set fastRiseAlarm(bool value) {
    prefs.setBool(AlarmSettingsNames.fastRiseAlarm.name, value);

    settings.notify();
  }

  int get fastRiseAlarmMinutes => prefs
      .getInt(AlarmSettingsNames.fastRiseAlarmMinutes.name, defaultValue: 30)!;
  set fastRiseAlarmMinutes(int value) {
    var validValues = [5, 10, 15, 20, 30];
    if (!validValues.contains(value)) {
      return;
    }

    prefs.setInt(AlarmSettingsNames.fastRiseAlarmMinutes.name, value);
    settings.notify();
  }

  int get fastRiseDelta =>
      prefs.getInt(AlarmSettingsNames.fastRiseDelta.name, defaultValue: 20)!;
  set fastRiseDelta(int value) {
    if (value < 8) {
      value = 8;
    }
    prefs.setInt(AlarmSettingsNames.fastRiseDelta.name, value);

    settings.notify();
  }

  ////
  // Data Alarms
  ////

  // noDataAlarmMinutes
  int get noDataAlarmMinutes => prefs
      .getInt(AlarmSettingsNames.noDataAlarmMinutes.name, defaultValue: 30)!;
  set noDataAlarmMinutes(int value) {
    var validValues = [-1, 10, 20, 30];
    if (!validValues.contains(value)) {
      return;
    }

    prefs.setInt(AlarmSettingsNames.noDataAlarmMinutes.name, value);
    settings.notify();
  }

  ////
  /// Smart Alarms
  ////

  bool get smartSnooze =>
      prefs.getBool(AlarmSettingsNames.smartSnooze.name, defaultValue: false)!;
  set smartSnooze(bool value) {
    prefs.setBool(AlarmSettingsNames.smartSnooze.name, value);

    settings.notify();
  }

  ////
  /// Volume
  ////
  ///

  bool get volumeOveride => prefs.getBool(AlarmSettingsNames.volumeOveride.name,
      defaultValue: false)!;
  set volumeOveride(bool value) {
    prefs.setBool(AlarmSettingsNames.volumeOveride.name, value);

    settings.notify();
  }

  int get volumeOverrideValue => prefs
      .getInt(AlarmSettingsNames.volumeOverrideValue.name, defaultValue: 50)!;
  set volumeOverrideValue(int value) {
    prefs.setInt(AlarmSettingsNames.volumeOverrideValue.name, value);
    if (value < 0) {
      value = 0;
    } else if (value > 100) {
      value = 100;
    }

    settings.notify();
  }

  int get volumeProgressionSeconds =>
      prefs.getInt(AlarmSettingsNames.volumeProgressionSeconds.name,
          defaultValue: 10)!;
  set volumeProgressionSeconds(int value) {
    var validValues = [-1, 10, 20, 30, 60, 120];
    if (!validValues.contains(value)) {
      return;
    }

    prefs.setInt(AlarmSettingsNames.volumeProgressionSeconds.name, value);

    settings.notify();
  }

  AlarmSounds get alarmAsset {
    var asset = prefs.getString('alarmAsset', defaultValue: 'Nightguard');
    return AlarmSounds.values.firstWhere((e) => e.name == asset,
        orElse: () => AlarmSounds.nightguard);
  }

  set alarmAsset(AlarmSounds value) {
    prefs.setString('alarmAsset', value.name);
    settings.notify();
  }

  // ephermeral
  bool get testAlarmPlaying => _testAlarmPlaying;
  set testAlarmPlaying(bool value) {
    if (value == _testAlarmPlaying) {
      return;
    }
    _testAlarmPlaying = value;
    settings.notify();
  }
}
