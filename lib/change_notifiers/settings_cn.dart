import 'dart:async';

import 'package:carer/change_notifiers/settings/alarm_settings.dart';
import 'package:carer/change_notifiers/settings/debug_settings.dart';
import 'package:carer/change_notifiers/settings/target_settings.dart';
import 'package:carer/change_notifiers/settings/ui_settings.dart';
import 'package:carer/models/constants.dart';
import 'package:carer/sql/key_value_store.dart';
import 'package:flutter/foundation.dart';
import 'package:signals/signals_flutter.dart';

enum SettingNames {
  // NS Settings
  nightscoutUrl,

  // Unit for BGL
  unit;
}

Map<SettingNames, Signal> settingsSignals = {
  SettingNames.nightscoutUrl: Signal<String?>(null),
  SettingNames.unit: Signal<Unit?>(null),
};

var nightscoutURLAndToken = computed(() {
  var nightscoutURL = SettingNames.nightscoutUrl.signal.value;
  if (nightscoutURL.isNotEmpty) {
    var uri = Uri.parse(nightscoutURL);
    var token = uri.queryParameters["token"];
    token ??= '';
    var base = '${uri.scheme}://${uri.host}';
    return (base.toString(), token);
  }

  return ('', '');
});

extension SettingNamesExtension on SettingNames {
  Signal get signal {
    return settingsSignals[this]!;
  }
}

class SettingsCN extends ChangeNotifier {
  late KeyValueStore prefs;
  late DebugSettings debugSettings;
  late TargetSettings targetSettings;
  late UISettings uiSettings;
  late AlarmSettings alarmSettings;

  Future<void> populate() async {
    // Get instance to the KVStore
    prefs = await KeyValueStore.instance;
    SettingNames.nightscoutUrl.signal.value =
        prefs.getString(SettingNames.nightscoutUrl.name);
    SettingNames.unit.signal.value =
        UnitExtension.fromBool(prefs.getBool(SettingNames.unit.name));

    // Sets the DataBase to the value when set
    effect(() => prefs.setString(SettingNames.nightscoutUrl.name,
        SettingNames.nightscoutUrl.signal.value));

    effect(() => prefs.setBool(
        SettingNames.unit.name, SettingNames.unit.signal.value.toBool()));

    uiSettings = UISettings(prefs: prefs, settings: this);

    targetSettings = TargetSettings(prefs: prefs, settings: this);

    alarmSettings = AlarmSettings(prefs: prefs, settings: this);

    debugSettings = DebugSettings(prefs: prefs, settings: this);
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

  void notify() {
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
