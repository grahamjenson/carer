import 'package:shared_preferences/shared_preferences.dart';

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
  static const String _nightscoutUrl = "nightscoutUrl";
  static const String _unit = "unit";
  static const String _screenActive = "screenActive";

  static Future<(String, String)> getNightScoutURLToken() async {
    final prefs = await SharedPreferences.getInstance();
    var pref = prefs.getString(_nightscoutUrl);
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
    final prefs = await SharedPreferences.getInstance();
    var pref = prefs.getString(_nightscoutUrl);
    if (pref != null && pref.isNotEmpty) {
      return pref;
    }
    return '';
  }

  static Future<void> setNightScoutURL(String value) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(_nightscoutUrl, value);
  }

  static Future<Unit> getUnit() async {
    final prefs = await SharedPreferences.getInstance();
    return UnitExtension.fromBool(prefs.getBool(_unit));
  }

  static Future<void> setUnit(Unit value) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool(_unit, value.toBool());
  }

  static Future<bool> getScreenActive() async {
    final prefs = await SharedPreferences.getInstance();
    var pref = prefs.getBool(_screenActive);
    if (pref != null) {
      return pref;
    }
    return true;
  }

  static Future<void> setScreenActive(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool(_screenActive, value);
  }
}
