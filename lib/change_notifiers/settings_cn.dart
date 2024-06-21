import 'dart:async';

import 'package:carer/change_notifiers/settings/alarm_settings.dart';
import 'package:carer/change_notifiers/settings/debug_settings.dart';
import 'package:carer/change_notifiers/settings/target_settings.dart';
import 'package:carer/change_notifiers/settings/ui_settings.dart';
import 'package:carer/models/constants.dart';
import 'package:carer/sql/key_value_store.dart';
import 'package:flutter/foundation.dart';
import 'package:signals/signals_flutter.dart';

Map<Settings, Signal> settingsSignals = {};

enum Settings {
  // NS Settings
  nightscoutUrl,

  // Unit for BGL
  unit;

  Signal get signal {
    return settingsSignals[this]!;
  }
}

var nightscoutURLAndToken = computed(() {
  var nightscoutURL = Settings.nightscoutUrl.signal.value;
  if (nightscoutURL.isNotEmpty) {
    var uri = Uri.parse(nightscoutURL);
    var token = uri.queryParameters["token"];
    token ??= '';
    var base = '${uri.scheme}://${uri.host}';
    return (base.toString(), token);
  }

  return ('', '');
});

class SettingsCN extends ChangeNotifier {
  late KeyValueStore prefs;
  late DebugSettings debugSettings;
  late TargetSettings targetSettings;
  late UISettingsCN uiSettings;
  late AlarmSettings alarmSettings;

  Future<void> populate() async {
    // Get instance to the KVStore
    prefs = await KeyValueStore.instance;

    settingsSignals = {
      Settings.nightscoutUrl:
          Signal<String?>(prefs.getString(Settings.nightscoutUrl.name)),
      Settings.unit:
          Signal<Unit>(Unit.fromBool(prefs.getBool(Settings.unit.name))),
    };

    // On Signal change update the KVStore
    effect(() => prefs.setString(
        Settings.nightscoutUrl.name, Settings.nightscoutUrl.signal.value));

    effect(() => prefs.setBool(
        Settings.unit.name, (Settings.unit.signal.value as Unit).toBool()));

    uiSettings = UISettingsCN(prefs: prefs, settings: this);

    targetSettings = TargetSettings(prefs: prefs, settings: this);

    alarmSettings = AlarmSettings(prefs: prefs, settings: this);

    debugSettings = DebugSettings(prefs: prefs, settings: this);
  }

  @override
  String toString() {
    var string = "{\n";
    for (var key in prefs.getKeys()) {
      if (key == Settings.nightscoutUrl.name) {
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
