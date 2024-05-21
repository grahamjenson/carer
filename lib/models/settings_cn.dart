import 'package:carer/models/models.dart';
import 'package:carer/models/settings/alarm_settings.dart';
import 'package:carer/models/settings/debug_settings.dart';
import 'package:carer/models/settings/target_settings.dart';
import 'package:carer/models/settings/ui_settings.dart';
import 'package:carer/sql/key_value_store.dart';
import 'package:flutter/material.dart';

enum SettingNames {
  // NS Settings
  nightscoutUrl,

  // Unit for BGL
  unit,
}

class Settings extends ChangeNotifier {
  late KeyValueStore prefs;
  late DebugSettings debugSettings;
  late TargetSettings targetSettings;
  late UISettings uiSettings;
  late AlarmSettings alarmSettings;

  Future<void> populate() async {
    prefs = await KeyValueStore.create();

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
    var string = "{\n";
    for (var key in prefs.getKeys()) {
      if (key == SettingNames.nightscoutUrl.name) {
        string += "\"$key\": \"[Filtered]\",\n";
        continue;
      }
      string += "\"$key\": \"${prefs.get(key)}\",\n";
    }
    string += "\"end\": true\n";
    string += "\n}";
    return string;
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

  void notify() {
    notifyListeners();
  }

  String get nightscoutURL =>
      prefs.getString(SettingNames.nightscoutUrl.name) ?? '';

  set nightscoutURL(String value) {
    prefs.setString(SettingNames.nightscoutUrl.name, value);
    notifyListeners();
  }

  // UNIT
  Unit get unit =>
      UnitExtension.fromBool(prefs.getBool(SettingNames.unit.name));

  set unit(Unit value) {
    prefs.setBool(SettingNames.unit.name, value.toBool());
    notifyListeners();
  }

  // UI
  bool get screenActive => uiSettings.screenActive;
  set screenActive(bool value) => uiSettings.screenActive = value;

  // targets
  int get targetHigh => targetSettings.targetHigh;
  int get targetLow => targetSettings.targetLow;
  int get urgentHigh => targetSettings.urgentHigh;
  int get urgentLow => targetSettings.urgentLow;

  set targetHigh(int value) => targetSettings.targetHigh = value;
  set targetLow(int value) => targetSettings.targetLow = value;
  set urgentHigh(int value) => targetSettings.urgentHigh = value;
  set urgentLow(int value) => targetSettings.urgentLow = value;

  // debug
  bool get debug => debugSettings.debug;
  set debug(bool value) => debugSettings.debug = value;

  DebugSummary get debugSummary => debugSettings.debugSummary;
  set debugSummary(DebugSummary value) => debugSettings.debugSummary = value;
}
