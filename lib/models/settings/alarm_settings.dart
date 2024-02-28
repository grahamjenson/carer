import 'package:carer/models/settings_cn.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

enum AlarmSettingsNames { lowAlarm, highAlarm, showChart }

class AlarmSettings {
  SharedPreferences prefs;
  Settings settings;

  bool _lowAlarm = true;
  bool _highAlarm = true;

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
}
