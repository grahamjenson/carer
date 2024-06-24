import 'dart:async';

import 'package:carer/change_notifiers/settings/alarm_settings.dart';
import 'package:carer/change_notifiers/settings/target_settings.dart';
import 'package:carer/change_notifiers/settings/ui_settings.dart';
import 'package:carer/models/constants.dart';
import 'package:carer/sql/key_value_store.dart';
import 'package:signals/signals_flutter.dart';

Map<Settings, Signal> _settingsSignals = {};

enum Settings {
  // NS Settings
  nightscoutUrl,

  // Unit for BGL
  unit;

  Signal get _signal {
    return _settingsSignals[this]!;
  }

  set value(dynamic value) {
    _settingsSignals[this]!.value = value;
  }

  get value {
    return _settingsSignals[this]!.value;
  }
}

var nightscoutURLAndToken = computed(() {
  var nightscoutURL = Settings.nightscoutUrl._signal.value;
  if (nightscoutURL.isNotEmpty) {
    var uri = Uri.parse(nightscoutURL);
    var token = uri.queryParameters["token"];
    token ??= '';
    var base = '${uri.scheme}://${uri.host}';
    return (base.toString(), token);
  }

  return ('', '');
});

class SettingsCN {
  late KeyValueStore prefs;
  late TargetSettingsCN targetSettings;
  late UISettingsCN uiSettings;
  late AlarmSettingsCN alarmSettings;

  Future<void> populate() async {
    // Get instance to the KVStore
    prefs = await KeyValueStore.instance;

    _settingsSignals = {
      Settings.nightscoutUrl:
          Signal<String?>(prefs.getString(Settings.nightscoutUrl.name)),
      Settings.unit:
          Signal<Unit>(Unit.fromBool(prefs.getBool(Settings.unit.name))),
    };

    // On Signal change update the KVStore
    effect(() {
      if (Settings.nightscoutUrl.value == null) {
        return;
      }
      prefs.setString(
          Settings.nightscoutUrl.name, Settings.nightscoutUrl.value);
    });

    effect(() => prefs.setBool(
        Settings.unit.name, (Settings.unit.value as Unit).toBool()));

    uiSettings = UISettingsCN(prefs: prefs, settings: this);

    targetSettings = TargetSettingsCN(prefs: prefs, settings: this);

    alarmSettings = AlarmSettingsCN(prefs: prefs, settings: this);
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
}
