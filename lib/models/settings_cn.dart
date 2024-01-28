import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum SettingNames { nightscoutUrl, unit, screenActive, rangeHigh, rangeLow }

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
  late SharedPreferences prefs;

  String nightscoutURL = '';
  Unit unit = Unit.mmol;
  bool screenActive = true;
  int rangeHigh = 180;
  int rangeLow = 72;

  Future<void> populate() async {
    prefs = await SharedPreferences.getInstance();

    var urlPref = prefs.getString(SettingNames.nightscoutUrl.name);
    if (urlPref != null && urlPref.isNotEmpty) {
      nightscoutURL = urlPref;
    }

    var unitPref = prefs.getBool(SettingNames.unit.name);
    if (unitPref != null) {
      unit = UnitExtension.fromBool(unitPref);
    }

    var screenActivePref = prefs.getBool(SettingNames.unit.name);
    if (screenActivePref != null) {
      screenActive = screenActivePref;
    }

    var rangeHighPref = prefs.getInt(SettingNames.rangeHigh.name);
    if (rangeHighPref != null) {
      rangeHigh = rangeHighPref;
    }

    var rangeLowPref = prefs.getInt(SettingNames.rangeLow.name);
    if (rangeLowPref != null) {
      rangeLow = rangeLowPref;
    }
  }

  @override
  String toString() {
    return 'Settings{nightscoutURL: $nightscoutURL, unit: $unit, screenActive: $screenActive, rangeHigh: $rangeHigh, rangeLow: $rangeLow}';
  }

  ////
  // NIGHT SCOUT URL
  ////
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

  Future<void> setNightscoutURL(String value) async {
    prefs.setString(SettingNames.nightscoutUrl.name, value);
    nightscoutURL = value;
    notifyListeners();
  }

  ////
  // UNIT
  ////

  Future<void> setUnit(Unit value) async {
    prefs.setBool(SettingNames.unit.name, value.toBool());
    unit = value;
    notifyListeners();
  }

  ////
  // SCREEN ACTIVE
  ////

  Future<void> setScreenActive(bool value) async {
    prefs.setBool(SettingNames.unit.name, value);
    screenActive = value;
    notifyListeners();
  }

  ////
  // RANGE HIGH
  ////

  Future<void> setRangeHigh(int value) async {
    rangeHigh = value;
    await setInt(SettingNames.rangeHigh, value);
  }

  ////
  // RANGE LOW
  ////

  Future<void> setRangeLow(int value) async {
    rangeLow = value;
    await setInt(SettingNames.rangeLow, value);
  }

  // PRIVATE FUNCTIONS
  Future<void> setInt(SettingNames name, int value) async {
    await prefs.setInt(name.name, value);
    notifyListeners();
  }
}
