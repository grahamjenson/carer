import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum SettingNames {
  nightscoutUrl,
  unit,
  screenActive,
  targetHigh,
  targetLow,
  urgentHigh,
  urgentLow
}

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

  String str(double value) {
    switch (this) {
      case Unit.mmol:
        return (value / 18).toStringAsFixed(1);
      case Unit.mg:
        return value.toStringAsFixed(0);
      default:
        return value.toStringAsFixed(0);
    }
  }
}

class Settings extends ChangeNotifier {
  late SharedPreferences prefs;

  String nightscoutURL = '';
  Unit unit = Unit.mmol;
  bool screenActive = true;
  int targetHigh = 180;
  int targetLow = 72;
  int urgentHigh = 270;
  int urgentLow = 55;

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

    var targetHighPref = prefs.getInt(SettingNames.targetHigh.name);
    if (targetHighPref != null) {
      targetHigh = targetHighPref;
    }

    var targetLowPref = prefs.getInt(SettingNames.targetLow.name);
    if (targetLowPref != null) {
      targetLow = targetLowPref;
    }

    var urgentHighPref = prefs.getInt(SettingNames.urgentHigh.name);
    if (urgentHighPref != null) {
      urgentHigh = urgentHighPref;
    }

    var urgentLowPref = prefs.getInt(SettingNames.urgentLow.name);
    if (urgentLowPref != null) {
      urgentLow = urgentLowPref;
    }
  }

  @override
  String toString() {
    return 'Settings{nightscoutURL: $nightscoutURL, unit: $unit, screenActive: $screenActive, targetHigh: $targetHigh, targetLow: $targetLow}';
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

  Future<void> setNightscoutURL(String value) async {
    prefs.setString(SettingNames.nightscoutUrl.name, value);
    nightscoutURL = value;
    notifyListeners();
  }

  // UNIT

  Future<void> setUnit(Unit value) async {
    prefs.setBool(SettingNames.unit.name, value.toBool());
    unit = value;
    notifyListeners();
  }

  // SCREEN ACTIVE

  Future<void> setScreenActive(bool value) async {
    prefs.setBool(SettingNames.unit.name, value);
    screenActive = value;
    notifyListeners();
  }

  // target HIGH

  Future<void> setTargetHigh(int nTargetHigh) async {
    if (!validTargets(urgentLow, targetLow, nTargetHigh, urgentHigh)) {
      return;
    }

    targetHigh = nTargetHigh;
    await setInt(SettingNames.targetHigh, nTargetHigh);
  }

  // target LOW

  Future<void> setTargetLow(int nTargetLow) async {
    if (!validTargets(urgentLow, nTargetLow, targetHigh, urgentHigh)) {
      return;
    }

    targetLow = nTargetLow;
    await setInt(SettingNames.targetLow, nTargetLow);
  }

  // Urgent HIGH

  Future<void> setUrgentHigh(int nUrgentHigh) async {
    if (!validTargets(urgentLow, targetLow, targetHigh, nUrgentHigh)) {
      return;
    }

    urgentHigh = nUrgentHigh;
    await setInt(SettingNames.urgentHigh, nUrgentHigh);
  }

  // Urgent LOW

  Future<void> setUrgentLow(int nUrgentLow) async {
    if (!validTargets(nUrgentLow, targetLow, targetHigh, urgentHigh)) {
      return;
    }

    urgentLow = nUrgentLow;
    await setInt(SettingNames.urgentLow, nUrgentLow);
  }

  bool validTargets(
      int urgentLow, int targetLow, int targetHigh, int urgentHigh) {
    return 9 <= urgentLow &&
        urgentLow <= targetLow &&
        targetLow <= targetHigh &&
        targetHigh <= urgentHigh &&
        urgentHigh <= 360;
  }

  ////
  // PRIVATE FUNCTIONS
  ////
  Future<void> setInt(SettingNames name, int value) async {
    await prefs.setInt(name.name, value);
    notifyListeners();
  }
}
