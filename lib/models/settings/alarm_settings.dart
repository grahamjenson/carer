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

  fastRiseAlarm,

  noDataAlarmMinutes,

  predictionAlgorithm,
  predictiveSnooze,

  volumeOverride,
  volumeProgressionMinutes,
}

enum PredictionAlgorithm { none, simple, profile }

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
  bool _fastRiseAlarm = false;

  // smart alarms
  PredictionAlgorithm _predictionAlgorithm = PredictionAlgorithm.none;

  PredictionAlgorithm _predictiveSnooze = PredictionAlgorithm.none;

  // data alarms
  int _noDataAlarmMinutes = 30;

  // volume
  int _volumeOverride = 50;
  int _volumeProgressionMinutes = 2;

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
    var volumeOverridePref =
        prefs.getInt(AlarmSettingsNames.volumeOverride.name);
    if (volumeOverridePref != null) {
      _volumeOverride = volumeOverridePref;
    }

    var volumeProgressionMinutesPref =
        prefs.getInt(AlarmSettingsNames.volumeProgressionMinutes.name);
    if (volumeProgressionMinutesPref != null) {
      _volumeProgressionMinutes = volumeProgressionMinutesPref;
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
    settings.notifyListeners();
  }

  bool get lowAlarm => _lowAlarm;
  set lowAlarm(bool value) {
    prefs.setBool(AlarmSettingsNames.lowAlarm.name, value);
    _lowAlarm = value;
    WakelockPlus.toggle(enable: value);
    settings.notifyListeners();
  }

  // highAlarm
  bool get highAlarm => _highAlarm;
  set highAlarm(bool value) {
    prefs.setBool(AlarmSettingsNames.highAlarm.name, value);
    _highAlarm = value;
    settings.notifyListeners();
  }

  int get lowMinutes => _lowMinutes;
  set lowMinutes(int value) {
    var validValues = [15, 20, 30, 45, 60];
    if (!validValues.contains(value)) {
      return;
    }

    prefs.setInt(AlarmSettingsNames.lowMinutes.name, value);
    _lowMinutes = value;
    settings.notifyListeners();
  }

  int get highMinutes => _highMinutes;
  set highMinutes(int value) {
    var validValues = [15, 20, 30, 45, 60];
    if (!validValues.contains(value)) {
      return;
    }

    prefs.setInt(AlarmSettingsNames.highMinutes.name, value);
    _highMinutes = value;
    settings.notifyListeners();
  }

  // urgentHighAlarm
  bool get urgentHighAlarm => _urgentHighAlarm;
  set urgentHighAlarm(bool value) {
    prefs.setBool(AlarmSettingsNames.urgentHighAlarm.name, value);
    _urgentHighAlarm = value;
    settings.notifyListeners();
  }

  ////
  // Diff Alarms
  ////

  // fasrDrop
  bool get fastDropAlarm => _fastDropAlarm;
  set fastDropAlarm(bool value) {
    prefs.setBool(AlarmSettingsNames.fastDropAlarm.name, value);
    _fastDropAlarm = value;
    settings.notifyListeners();
  }

  int get fastDropAlarmMinutes => _fastDropAlarmMinutes;
  set fastDropAlarmMinutes(int value) {
    var validValues = [15, 20, 30];
    if (!validValues.contains(value)) {
      return;
    }

    prefs.setInt(AlarmSettingsNames.fastDropAlarmMinutes.name, value);
    _fastDropAlarmMinutes = value;
    settings.notifyListeners();
  }

  // fastRise
  bool get fastRiseAlarm => _fastRiseAlarm;
  set fastRiseAlarm(bool value) {
    prefs.setBool(AlarmSettingsNames.fastRiseAlarm.name, value);
    _fastRiseAlarm = value;
    settings.notifyListeners();
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
    settings.notifyListeners();
  }

  ////
  /// Smart Alarms
  ////

  // predictionAlgorithm
  PredictionAlgorithm get predictionAlgorithm => _predictionAlgorithm;
  set predictionAlgorithm(PredictionAlgorithm value) {
    prefs.setString(AlarmSettingsNames.predictionAlgorithm.name, value.name);
    _predictionAlgorithm = value;
    settings.notifyListeners();
  }

  // predictiveSnooze
  PredictionAlgorithm get predictiveSnooze => _predictiveSnooze;
  set predictiveSnooze(PredictionAlgorithm value) {
    prefs.setString(AlarmSettingsNames.predictiveSnooze.name, value.name);
    _predictiveSnooze = value;
    settings.notifyListeners();
  }

  ////
  /// Volume
  ////

  int get volumeOverride => _volumeOverride;
  set volumeOverride(int value) {
    prefs.setInt(AlarmSettingsNames.volumeOverride.name, value);
    if (value < 0) {
      value = 0;
    } else if (value > 100) {
      value = 100;
    }
    _volumeOverride = value;
    settings.notifyListeners();
  }

  int get volumeProgressionMinutes => _volumeProgressionMinutes;
  set volumeProgressionMinutes(int value) {
    var validValues = [1, 2, 3, 4, 5];
    if (!validValues.contains(value)) {
      return;
    }

    prefs.setInt(AlarmSettingsNames.volumeProgressionMinutes.name, value);
    _volumeProgressionMinutes = value;
    settings.notifyListeners();
  }
}
