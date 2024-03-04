import 'package:carer/models/models.dart';
import 'package:carer/models/settings/alarm_settings.dart';
import 'package:carer/models/settings/debug_settings.dart';
import 'package:carer/models/settings/target_settings.dart';
import 'package:carer/models/settings/ui_settings.dart';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum SettingNames {
  // NS Settings
  nightscoutUrl,

  // Unit for BGL
  unit,
}

class Settings extends ChangeNotifier {
  late SharedPreferences prefs;
  late DebugSettings debugSettings;
  late TargetSettings targetSettings;
  late UISettings uiSettings;
  late AlarmSettings alarmSettings;

  String _nightscoutURL = '';
  Unit _unit = Unit.mmol;

  Future<void> populate() async {
    prefs = await SharedPreferences.getInstance();

    var urlPref = prefs.getString(SettingNames.nightscoutUrl.name);
    if (urlPref != null && urlPref.isNotEmpty) {
      _nightscoutURL = urlPref;
    }

    var unitPref = prefs.getBool(SettingNames.unit.name);
    if (unitPref != null) {
      _unit = UnitExtension.fromBool(unitPref);
    }

    uiSettings = UISettings(prefs: prefs, settings: this);
    uiSettings.populate();

    targetSettings = TargetSettings(prefs: prefs, settings: this);
    targetSettings.populate();

    alarmSettings = AlarmSettings(prefs: prefs, settings: this);
    alarmSettings.populate();

    debugSettings = DebugSettings(prefs: prefs, settings: this);
    debugSettings.populate();
  }

  @override
  String toString() {
    return 'Settings{nightscoutURL: $nightscoutURL, unit: $unit, screenActive: $screenActive, targetHigh: $targetHigh, targetLow: $targetLow}';
  }

  // NIGHT SCOUT URL

  (String, String) get nightscoutURLAndToken {
    if (nightscoutURL.isNotEmpty) {
      var uri = Uri.parse(nightscoutURL);
      var token = uri.queryParameters["token"];
      token ??= '';
      var base = '${uri.scheme}://${uri.host}';
      return (base.toString(), token);
    }

    return ('', '');
  }

  String get nightscoutURL => _nightscoutURL;
  set nightscoutURL(String value) {
    prefs.setString(SettingNames.nightscoutUrl.name, value);
    _nightscoutURL = value;
    notifyListeners();
  }

  // UNIT
  Unit get unit => _unit;
  set unit(Unit value) {
    prefs.setBool(SettingNames.unit.name, value.toBool());
    _unit = value;
    notifyListeners();
  }

  // UI
  bool get screenActive => uiSettings.screenActive;
  set screenActive(bool value) => uiSettings.screenActive = value;

  bool get showHistory => uiSettings.showHistory;
  set showHistory(bool value) => uiSettings.showHistory = value;

  bool get showChart => uiSettings.showChart;
  set showChart(bool value) => uiSettings.showChart = value;

  // targets
  int get targetHigh => targetSettings.targetHigh;
  int get targetLow => targetSettings.targetLow;
  int get urgentHigh => targetSettings.urgentHigh;
  int get urgentLow => targetSettings.urgentLow;

  set targetHigh(int value) => targetSettings.targetHigh = value;
  set targetLow(int value) => targetSettings.targetLow = value;
  set urgentHigh(int value) => targetSettings.urgentHigh = value;
  set urgentLow(int value) => targetSettings.urgentLow = value;

  //alarms
  bool get lowAlarm => alarmSettings.lowAlarm;
  set lowAlarm(bool value) => alarmSettings.lowAlarm = value;

  bool get highAlarm => alarmSettings.highAlarm;
  set highAlarm(bool value) => alarmSettings.highAlarm = value;

  // debug
  bool get debug => debugSettings.debug;
  set debug(bool value) => debugSettings.debug = value;

  DebugSummary get debugSummary => debugSettings.debugSummary;
  set debugSummary(DebugSummary value) => debugSettings.debugSummary = value;
}
