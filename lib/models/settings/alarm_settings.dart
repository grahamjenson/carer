import 'package:carer/models/settings_cn.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

enum AlarmSettingsNames {
  lowAlarm,
  highAlarm,

  fastDropAlarm,
  fastRiseAlarm,
}

enum PredictionAlgorithm { dumb }

class AlarmSettings {
  SharedPreferences prefs;
  Settings settings;

  bool _lowAlarm = false;
  bool _highAlarm = false;

  bool _fastDropAlarm = false;
  bool _fastRiseAlarm = false;

  PredictionAlgorithm? _predictionAlgorithm;

  AlarmSettings({required this.prefs, required this.settings});

  void populate() {
    var lowAlarmPref = prefs.getBool(AlarmSettingsNames.lowAlarm.name);
    if (lowAlarmPref != null) {
      _lowAlarm = lowAlarmPref;
    }

    var highAlarmPref = prefs.getBool(AlarmSettingsNames.highAlarm.name);
    if (highAlarmPref != null) {
      _highAlarm = highAlarmPref;
    }

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
  }

  // Screen Active
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

  // fasrDrop
  bool get fastDropAlarm => _fastDropAlarm;
  set fastDropAlarm(bool value) {
    prefs.setBool(AlarmSettingsNames.fastDropAlarm.name, value);
    _fastDropAlarm = value;
    settings.notifyListeners();
  }

  // fastRise
  bool get fastRiseAlarm => _fastRiseAlarm;
  set fastRiseAlarm(bool value) {
    prefs.setBool(AlarmSettingsNames.fastRiseAlarm.name, value);
    _fastRiseAlarm = value;
    settings.notifyListeners();
  }

  PredictionAlgorithm? get predictionAlgorithm => _predictionAlgorithm;
  set predictionAlgorithm(PredictionAlgorithm? value) {
    _predictionAlgorithm = value;
  }
}
