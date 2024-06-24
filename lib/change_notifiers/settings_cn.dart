import 'package:carer/change_notifiers/settings/alarm_settings.dart';
import 'package:carer/change_notifiers/settings/target_settings.dart';
import 'package:carer/change_notifiers/settings/ui_settings.dart';
import 'package:carer/models/constants.dart';
import 'package:carer/sql/key_value_store.dart';
import 'package:signals/signals_flutter.dart';

enum SNames {
  nightscoutUrl,
  unit,
}

class Settings {
  static final Settings _singleton = Settings._();
  factory Settings() => _singleton;

  Map<SNames, Signal> _signals = {};
  late final Computed<(String, String)> _nightscoutURLAndTokenSignal;

  Settings._() {
    _signals = {
      SNames.nightscoutUrl: Signal<String?>(null),
      SNames.unit: Signal<Unit>(Unit.mg),
    };

    _nightscoutURLAndTokenSignal = computed(() {
      if (nightscoutURL == null || nightscoutURL!.isEmpty) {
        return ('', '');
      }

      var uri = Uri.parse(nightscoutURL!);
      var token = uri.queryParameters["token"];
      token ??= '';
      var base = '${uri.scheme}://${uri.host}';
      return (base.toString(), token);
    });
  }

  String? get nightscoutURL => _signals[SNames.nightscoutUrl]!.value as String?;
  set nightscoutURL(String? value) =>
      _signals[SNames.nightscoutUrl]!.value = value;

  Unit get unit => _signals[SNames.unit]!.value as Unit;
  set unit(Unit value) => _signals[SNames.unit]!.value = value;

  (String, String) get nightscoutURLAndToken =>
      _nightscoutURLAndTokenSignal.value;

  setupDBPropagation() async {
    var prefs = await KeyValueStore.instance;
    nightscoutURL = prefs.getString(SNames.nightscoutUrl.name);
    unit = Unit.fromBool(prefs.getBool(SNames.unit.name, defaultValue: true)!);

    effect(() {
      if (nightscoutURL == null) {
        return;
      }
      prefs.setString(SNames.nightscoutUrl.name, nightscoutURL!);
    });

    effect(() => prefs.setBool(SNames.unit.name, unit.toBool()));

    // Legacy
    var uiSettings = UISettingsCN(prefs: prefs);

    var targetSettings = TargetSettingsCN(prefs: prefs);

    var alarmSettings = AlarmSettingsCN(prefs: prefs);
  }
}
