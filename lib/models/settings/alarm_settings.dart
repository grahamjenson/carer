import 'package:carer/models/settings_cn.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

enum AlarmSettingsNames {
  urgentLowAlarm,
  lowAlarm,
  lowMinutes,
  highAlarm,
  highMinutes,
  urgentHighAlarm,

  fastDropAlarm,
  fastDropAlarmMinutes,
  fastDropAlarmDelta,

  fastRiseAlarm,
  fastRiseAlarmMinutes,
  fastRiseAlarmDelta,

  noDataAlarmMinutes,

  predictionAlgorithm,
  predictiveSnooze,

  volumeOveride,
  volumeOverrideValue,
  volumeProgressionSeconds,
}

enum PredictionAlgorithm { none, simple, profile }

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
  SharedPreferences prefs;
  Settings settings;

  // Boundary Alarms
  bool _urgentLowlarm = false;
  bool _lowAlarm = false;
  int _lowMinutes = 30;
  bool _highAlarm = false;
  int _highMinutes = 30;
  bool _urgentHighAlarm = false;

  // Diff Alarms
  bool _fastDropAlarm = false;
  int _fastDropAlarmMinutes = 30;
  int _fastDropAlarmDelta = 20;
  bool _fastRiseAlarm = false;
  int _fastRiseAlarmMinutes = 30;
  int _fastRiseAlarmDelta = 20;

  // smart alarms
  PredictionAlgorithm _predictionAlgorithm = PredictionAlgorithm.none;

  PredictionAlgorithm _predictiveSnooze = PredictionAlgorithm.none;

  // data alarms
  int _noDataAlarmMinutes = 30;

  // volume
  bool _volumeOveride = false;
  int _volumeOverrideValue = 50;
  int _volumeProgressionSeconds = 2;

  AlarmSounds _alarmAsset = AlarmSounds.nightguard;

  // ephemeral properters
  bool _testAlarmPlaying = false;

  AlarmSettings({required this.prefs, required this.settings});

  void populate() {
    // Boundary Alarms
    var urgentLowAlarmPref =
        prefs.getBool(AlarmSettingsNames.urgentLowAlarm.name);
    if (urgentLowAlarmPref != null) {
      _urgentLowlarm = urgentLowAlarmPref;
    }

    var lowAlarmPref = prefs.getBool(AlarmSettingsNames.lowAlarm.name);
    if (lowAlarmPref != null) {
      _lowAlarm = lowAlarmPref;
    }

    var lowMinutesPref = prefs.getInt(AlarmSettingsNames.lowMinutes.name);
    if (lowMinutesPref != null) {
      _lowMinutes = lowMinutesPref;
    }

    var highAlarmPref = prefs.getBool(AlarmSettingsNames.highAlarm.name);
    if (highAlarmPref != null) {
      _highAlarm = highAlarmPref;
    }

    var highMinutesPref = prefs.getInt(AlarmSettingsNames.highMinutes.name);
    if (highMinutesPref != null) {
      _highMinutes = highMinutesPref;
    }

    var urgentHighAlarmPref =
        prefs.getBool(AlarmSettingsNames.urgentHighAlarm.name);
    if (urgentHighAlarmPref != null) {
      _urgentHighAlarm = urgentHighAlarmPref;
    }

    // Diff Alarms
    var fastDropAlarmPref =
        prefs.getBool(AlarmSettingsNames.fastDropAlarm.name);
    if (fastDropAlarmPref != null) {
      _fastDropAlarm = fastDropAlarmPref;
    }

    var fastRiseAlarmPref =
        prefs.getBool(AlarmSettingsNames.fastRiseAlarm.name);
    if (fastRiseAlarmPref != null) {
      _fastRiseAlarm = fastRiseAlarmPref;
    }

    // data alarms
    var noDataAlarmMinutesPref =
        prefs.getInt(AlarmSettingsNames.noDataAlarmMinutes.name);
    if (noDataAlarmMinutesPref != null) {
      _noDataAlarmMinutes = noDataAlarmMinutesPref;
    }

    // smart alarms
    var predictionAlgorithmPref =
        prefs.getString(AlarmSettingsNames.predictionAlgorithm.name);
    if (predictionAlgorithmPref != null) {
      _predictionAlgorithm = PredictionAlgorithm.values.firstWhere(
          (e) => e.name == predictionAlgorithmPref,
          orElse: () => PredictionAlgorithm.none);
    }

    var predictiveSnoozePref =
        prefs.getString(AlarmSettingsNames.predictiveSnooze.name);
    if (predictiveSnoozePref != null) {
      _predictiveSnooze = PredictionAlgorithm.values.firstWhere(
          (e) => e.name == predictiveSnoozePref,
          orElse: () => PredictionAlgorithm.none);
    }

    // volume
    var volumeOveridePref =
        prefs.getBool(AlarmSettingsNames.volumeOveride.name);
    if (volumeOveridePref != null) {
      _volumeOveride = volumeOveridePref;
    }

    var volumeOverrideValuePref =
        prefs.getInt(AlarmSettingsNames.volumeOverrideValue.name);
    if (volumeOverrideValuePref != null) {
      _volumeOverrideValue = volumeOverrideValuePref;
    }

    var volumeProgressionSecondsPref =
        prefs.getInt(AlarmSettingsNames.volumeProgressionSeconds.name);
    if (volumeProgressionSecondsPref != null) {
      _volumeProgressionSeconds = volumeProgressionSecondsPref;
    }

    var alarmAssetPref = prefs.getString('alarmAsset');
    if (alarmAssetPref != null) {
      _alarmAsset = AlarmSounds.values.firstWhere(
          (e) => e.name == alarmAssetPref,
          orElse: () => AlarmSounds.nightguard);
    }
  }

  ////
  // Boundary Alarms
  ////

  // urgentLowAlarm
  bool get urgentLowAlarm => _urgentLowlarm;
  set urgentLowAlarm(bool value) {
    prefs.setBool(AlarmSettingsNames.urgentLowAlarm.name, value);
    _urgentLowlarm = value;
    settings.notify();
  }

  bool get lowAlarm => _lowAlarm;
  set lowAlarm(bool value) {
    prefs.setBool(AlarmSettingsNames.lowAlarm.name, value);
    _lowAlarm = value;
    WakelockPlus.toggle(enable: value);
    settings.notify();
  }

  // highAlarm
  bool get highAlarm => _highAlarm;
  set highAlarm(bool value) {
    prefs.setBool(AlarmSettingsNames.highAlarm.name, value);
    _highAlarm = value;
    settings.notify();
  }

  int get lowMinutes => _lowMinutes;
  set lowMinutes(int value) {
    var validValues = [0, 5, 10, 15, 20, 30, 45, 60];
    if (!validValues.contains(value)) {
      return;
    }

    prefs.setInt(AlarmSettingsNames.lowMinutes.name, value);
    _lowMinutes = value;
    settings.notify();
  }

  int get highMinutes => _highMinutes;
  set highMinutes(int value) {
    var validValues = [0, 5, 10, 15, 20, 30, 45, 60];
    if (!validValues.contains(value)) {
      return;
    }

    prefs.setInt(AlarmSettingsNames.highMinutes.name, value);
    _highMinutes = value;
    settings.notify();
  }

  // urgentHighAlarm
  bool get urgentHighAlarm => _urgentHighAlarm;
  set urgentHighAlarm(bool value) {
    prefs.setBool(AlarmSettingsNames.urgentHighAlarm.name, value);
    _urgentHighAlarm = value;
    settings.notify();
  }

  ////
  // Diff Alarms
  ////

  // fasrDrop
  bool get fastDropAlarm => _fastDropAlarm;
  set fastDropAlarm(bool value) {
    prefs.setBool(AlarmSettingsNames.fastDropAlarm.name, value);
    _fastDropAlarm = value;
    settings.notify();
  }

  int get fastDropAlarmMinutes => _fastDropAlarmMinutes;
  set fastDropAlarmMinutes(int value) {
    var validValues = [15, 20, 30];
    if (!validValues.contains(value)) {
      return;
    }

    prefs.setInt(AlarmSettingsNames.fastDropAlarmMinutes.name, value);
    _fastDropAlarmMinutes = value;
    settings.notify();
  }

  int get fastDropAlarmDelta => _fastDropAlarmDelta;
  set fastDropAlarmDelta(int value) {
    prefs.setInt(AlarmSettingsNames.fastDropAlarmDelta.name, value);
    _fastDropAlarmDelta = value;
    settings.notify();
  }

  // fastRise
  bool get fastRiseAlarm => _fastRiseAlarm;
  set fastRiseAlarm(bool value) {
    prefs.setBool(AlarmSettingsNames.fastRiseAlarm.name, value);
    _fastRiseAlarm = value;
    settings.notify();
  }

  int get fastRiseAlarmMinutes => _fastRiseAlarmMinutes;
  set fastRiseAlarmMinutes(int value) {
    var validValues = [15, 20, 30];
    if (!validValues.contains(value)) {
      return;
    }

    prefs.setInt(AlarmSettingsNames.fastRiseAlarmMinutes.name, value);
    _fastRiseAlarmMinutes = value;
    settings.notify();
  }

  int get fastRiseAlarmDelta => _fastRiseAlarmDelta;
  set fastRiseAlarmDelta(int value) {
    prefs.setInt(AlarmSettingsNames.fastRiseAlarmDelta.name, value);
    _fastRiseAlarmDelta = value;
    settings.notify();
  }

  ////
  // Data Alarms
  ////

  // noDataAlarmMinutes
  int get noDataAlarmMinutes => _noDataAlarmMinutes;
  set noDataAlarmMinutes(int value) {
    var validValues = [-1, 10, 20, 30];
    if (!validValues.contains(value)) {
      return;
    }

    prefs.setInt(AlarmSettingsNames.noDataAlarmMinutes.name, value);
    _noDataAlarmMinutes = value;
    settings.notify();
  }

  ////
  /// Smart Alarms
  ////

  // predictionAlgorithm
  PredictionAlgorithm get predictionAlgorithm => _predictionAlgorithm;
  set predictionAlgorithm(PredictionAlgorithm value) {
    prefs.setString(AlarmSettingsNames.predictionAlgorithm.name, value.name);
    _predictionAlgorithm = value;
    settings.notify();
  }

  // predictiveSnooze
  PredictionAlgorithm get predictiveSnooze => _predictiveSnooze;
  set predictiveSnooze(PredictionAlgorithm value) {
    prefs.setString(AlarmSettingsNames.predictiveSnooze.name, value.name);
    _predictiveSnooze = value;
    settings.notify();
  }

  ////
  /// Volume
  ////
  ///

  bool get volumeOveride => _volumeOveride;
  set volumeOveride(bool value) {
    prefs.setBool(AlarmSettingsNames.volumeOveride.name, value);
    _volumeOveride = value;
    settings.notify();
  }

  int get volumeOverrideValue => _volumeOverrideValue;
  set volumeOverrideValue(int value) {
    prefs.setInt(AlarmSettingsNames.volumeOverrideValue.name, value);
    if (value < 0) {
      value = 0;
    } else if (value > 100) {
      value = 100;
    }
    _volumeOverrideValue = value;
    settings.notify();
  }

  int get volumeProgressionSeconds => _volumeProgressionSeconds;
  set volumeProgressionSeconds(int value) {
    var validValues = [-1, 10, 20, 30, 60, 120];
    if (!validValues.contains(value)) {
      return;
    }

    prefs.setInt(AlarmSettingsNames.volumeProgressionSeconds.name, value);
    _volumeProgressionSeconds = value;
    settings.notify();
  }

  AlarmSounds get alarmAsset => _alarmAsset;
  set alarmAsset(AlarmSounds value) {
    prefs.setString('alarmAsset', value.name);
    _alarmAsset = value;
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
