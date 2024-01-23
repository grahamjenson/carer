import 'package:flutter/material.dart';
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

class Settings extends ChangeNotifier {
  String nightScoutURL = '';
  Unit unit = Unit.mmol;
  bool screenActive = true;

  Future<void> populate() async {
    final prefs = await SharedPreferences.getInstance();
    var urlPref = prefs.getString(SettingNames.nightscoutUrl.name);
    var unitPref = prefs.getBool(SettingNames.unit.name);
    var screenActivePref = prefs.getBool(SettingNames.unit.name);

    if (urlPref != null && urlPref.isNotEmpty) {
      nightScoutURL = urlPref;
    }
    if (unitPref != null) {
      unit = UnitExtension.fromBool(unitPref);
    }
    if (screenActivePref != null) {
      screenActive = screenActivePref;
    }
  }

  @override
  String toString() {
    return 'Settings{nightScoutURL: $nightScoutURL, unit: $unit, screenActive: $screenActive}';
  }

  ////
  // NIGHT SCOUT URL
  ////
  (String, String) get nightScoutURLAndToken {
    if (nightScoutURL.isNotEmpty) {
      var uri = Uri.parse(nightScoutURL);
      var token = uri.queryParameters["token"];
      token ??= '';
      var base = '${uri.scheme}://${uri.host}';
      return (base.toString(), token);
    }

    return ('', '');
  }

  Future<void> setNightScoutURL(String value) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(SettingNames.nightscoutUrl.name, value);
    nightScoutURL = value;
  }

  ////
  // UNIT
  ////

  Future<void> setUnit(Unit value) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool(SettingNames.unit.name, value.toBool());
    unit = value;
  }

  ////
  // SCREEN ACTIVE
  ////

  Future<void> setScreenActive(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool(SettingNames.unit.name, value);
    screenActive = value;
  }
}
