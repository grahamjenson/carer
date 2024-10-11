import 'package:carer/services/settings/alarm_alert_settings.dart';
import 'package:carer/services/settings/alarm_settings.dart';
import 'package:carer/services/settings/device_settings.dart';
import 'package:carer/services/settings/secure_settings.dart';
import 'package:carer/services/settings/target_settings.dart';
import 'package:carer/services/settings/time_settings.dart';
import 'package:carer/services/settings/ui_settings.dart';
import 'package:carer/sql/key_value_store.dart';

class Settings {
  static final Settings _singleton = Settings._();
  factory Settings() => _singleton;

  final uiSettings = UISettings();
  final targetSettings = TargetSettings();
  final alarmSettings = AlarmSettings();
  final alarmAlertSettings = AlarmAlertSettings();
  final secureSettings = SecureSettings();
  final statusSettings = StatusSettings();
  final timeSettings = TimeSettings();
  Settings._();

  Future<bool> setupDBPropagation() async {
    var prefs = await KeyValueStore.instance;

    await secureSettings.setupDBPropagation();
    uiSettings.setupDBPropagation(prefs);
    targetSettings.setupDBPropagation(prefs);
    alarmSettings.setupDBPropagation(prefs);
    alarmAlertSettings.setupDBPropagation(prefs);
    statusSettings.setupDBPropagation(prefs);
    timeSettings.setupDBPropagation(prefs);

    return true;
  }
}
