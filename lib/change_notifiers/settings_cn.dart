import 'package:carer/change_notifiers/settings/alarm_settings.dart';
import 'package:carer/change_notifiers/settings/target_settings.dart';
import 'package:carer/change_notifiers/settings/ui_settings.dart';
import 'package:carer/models/constants.dart';
import 'package:carer/sql/key_value_store.dart';
import 'package:signals/signals_flutter.dart';

enum _SNames {
  nightscoutUrl,
  unit,
}

class Settings {
  static final Settings _singleton = Settings._();
  factory Settings() => _singleton;

  final uiSettings = UISettings();
  final targetSettings = TargetSettings();
  final alarmSettings = AlarmSettings();

  final Map<_SNames, Signal> _signals = {
    _SNames.nightscoutUrl: Signal<String?>(null, debugLabel: 'nightscoutUrl'),
    _SNames.unit: Signal<Unit>(Unit.mg, debugLabel: 'unit'),
  };

  late final Computed<(String, String)> _nightscoutURLAndTokenSignal;

  Settings._() {
    _nightscoutURLAndTokenSignal = computed(() {
      if (nightscoutURL == null || nightscoutURL!.isEmpty) {
        return ('', '');
      }

      var uri = Uri.parse(nightscoutURL!);
      var token = uri.queryParameters["token"];
      token ??= '';
      var base = '${uri.scheme}://${uri.host}';
      return (base.toString(), token);
    }, debugLabel: 'nightscoutURLAndToken');
  }

  String? get nightscoutURL =>
      _signals[_SNames.nightscoutUrl]!.value as String?;
  set nightscoutURL(String? value) =>
      _signals[_SNames.nightscoutUrl]!.value = value;

  Unit get unit => _signals[_SNames.unit]!.value as Unit;
  set unit(Unit value) => _signals[_SNames.unit]!.value = value;

  (String, String) get nightscoutURLAndToken =>
      _nightscoutURLAndTokenSignal.value;

  setupDBPropagation() async {
    var prefs = await KeyValueStore.instance;
    nightscoutURL = prefs.getString(_SNames.nightscoutUrl.name);
    unit = Unit.fromBool(prefs.getBool(_SNames.unit.name, defaultValue: true)!);

    effect(() {
      if (nightscoutURL == null) {
        return;
      }
      prefs.setString(_SNames.nightscoutUrl.name, nightscoutURL!);
    });

    effect(() => prefs.setBool(_SNames.unit.name, unit.toBool()));

    await uiSettings.setupDBPropagation();
    await targetSettings.setupDBPropagation();
    await alarmSettings.setupDBPropagation();
  }
}
