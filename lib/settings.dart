import 'package:shared_preferences/shared_preferences.dart';

enum SettingNames { nightscoutUrl, unit, screenActive }

enum Unit { mmol, mg }

extension UnitExtension on Unit {
  static Unit fromBool(bool? b) {
    if (b == false) {
      return Unit.mg;
    } else {
      return Unit.mmol; // default on null
    }
  }

  bool toBool() {
    switch (this) {
      case Unit.mmol:
        return true;
      case Unit.mg:
        return false;
      default:
        return true;
    }
  }

  String get name {
    switch (this) {
      case Unit.mmol:
        return 'mmol/L';
      case Unit.mg:
        return 'mg/dl';
      default:
        return "mmol/L";
    }
  }
}

class Settings {
  static final List<Function> _listeners = [];

  static addSettingsChangeListener(
      Function(SettingNames, dynamic) listener) async {
    _listeners.add(listener);
  }

  ////
  // NIGHT SCOUT URL
  ////
  static Future<(String, String)> getNightScoutURLToken() async {
    var setting = SettingNames.nightscoutUrl;
    final prefs = await SharedPreferences.getInstance();
    var pref = prefs.getString(setting.name);
    if (pref != null && pref.isNotEmpty) {
      var uri = Uri.parse(pref);
      var token = uri.queryParameters["token"];
      token ??= '';
      var base = '${uri.scheme}://${uri.host}';
      return (base.toString(), token);
    }

    return ('', '');
  }

  static Future<String> getNightScoutURL() async {
    var setting = SettingNames.nightscoutUrl;
    final prefs = await SharedPreferences.getInstance();
    var pref = prefs.getString(setting.name);
    if (pref != null && pref.isNotEmpty) {
      return pref;
    }
    return '';
  }

  static Future<void> setNightScoutURL(String value) async {
    var setting = SettingNames.nightscoutUrl;
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(setting.name, value);
    for (var element in _listeners) {
      element(setting, value);
    }
  }

  ////
  // UNIT
  ////

  static Future<Unit> getUnit() async {
    var setting = SettingNames.unit;
    final prefs = await SharedPreferences.getInstance();
    return UnitExtension.fromBool(prefs.getBool(setting.name));
  }

  static Future<void> setUnit(Unit value) async {
    var setting = SettingNames.unit;
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool(setting.name, value.toBool());
    for (var element in _listeners) {
      element(setting, value);
    }
  }

  ////
  // SCREEN ACTIVE
  ////

  static Future<bool> getScreenActive() async {
    var setting = SettingNames.unit;
    final prefs = await SharedPreferences.getInstance();
    var pref = prefs.getBool(setting.name);
    if (pref != null) {
      return pref;
    }
    return true;
  }

  static Future<void> setScreenActive(bool value) async {
    var setting = SettingNames.unit;
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool(setting.name, value);
    for (var element in _listeners) {
      element(setting, value);
    }
  }
}
