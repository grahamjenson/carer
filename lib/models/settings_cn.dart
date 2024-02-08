import 'package:carer/models/debug_settings.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum SettingNames {
  // NS Settings
  nightscoutUrl,

  // Unit for BGL
  unit,

  // App settings
  screenActive,

  // targets
  targetHigh,
  targetLow,
  urgentHigh,
  urgentLow,
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
  late DebugSettings debugSettings;

  String _nightscoutURL = '';
  Unit _unit = Unit.mmol;
  bool _screenActive = true;

  Map<String, int> targets = {
    SettingNames.targetHigh.name: 180,
    SettingNames.targetLow.name: 72,
    SettingNames.urgentHigh.name: 270,
    SettingNames.urgentLow.name: 55
  };

  Future<void> populate() async {
    prefs = await SharedPreferences.getInstance();

    var urlPref = prefs.getString(SettingNames.nightscoutUrl.name);
    if (urlPref != null && urlPref.isNotEmpty) {
      _nightscoutURL = urlPref;
    }

    var unitPref = prefs.getBool(SettingNames.unit.name);
    if (unitPref != null) {
      _unit = UnitExtension.fromBool(unitPref);
    }

    var screenActivePref = prefs.getBool(SettingNames.unit.name);
    if (screenActivePref != null) {
      _screenActive = screenActivePref;
    }

    for (var setting in targets.entries) {
      var value = prefs.getInt(setting.key);
      if (value != null) {
        targets[setting.key] = value;
      }
    }

    debugSettings =
        DebugSettings(prefs: prefs, notifyListeners: notifyListeners);
    debugSettings.populateDebugSettings();
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

  String get nightscoutURL => _nightscoutURL;
  set nightscoutURL(String value) {
    prefs.setString(SettingNames.nightscoutUrl.name, value);
    _nightscoutURL = value;
    notifyListeners();
  }

  // UNIT
  Unit get unit => _unit;
  set unit(Unit value) {
    prefs.setBool(SettingNames.unit.name, value.toBool());
    _unit = value;
    notifyListeners();
  }

  // SCREEN ACTIVE
  bool get screenActive => _screenActive;
  set screenActive(bool value) {
    prefs.setBool(SettingNames.unit.name, value);
    _screenActive = value;
    notifyListeners();
  }

  // getters
  int get targetHigh {
    return targets[SettingNames.targetHigh.name]!;
  }

  int get targetLow {
    return targets[SettingNames.targetLow.name]!;
  }

  int get urgentHigh {
    return targets[SettingNames.urgentHigh.name]!;
  }

  int get urgentLow {
    return targets[SettingNames.urgentLow.name]!;
  }

  // setters

  set targetHigh(int value) {
    setTarget(SettingNames.targetHigh, value);
  }

  set targetLow(int value) {
    setTarget(SettingNames.targetLow, value);
  }

  set urgentHigh(int value) {
    setTarget(SettingNames.urgentHigh, value);
  }

  set urgentLow(int value) {
    setTarget(SettingNames.urgentLow, value);
  }

  ////
  // private functions

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
  Future<void> setTarget(SettingNames setting, int value) async {
    var clone = Map<String, int>.from(targets);
    clone[setting.name] = value;
    if (validTargets(
        clone[SettingNames.urgentLow.name]!,
        clone[SettingNames.targetLow.name]!,
        clone[SettingNames.targetHigh.name]!,
        clone[SettingNames.urgentHigh.name]!)) {
      targets = clone;
    } else {
      return;
    }
    await prefs.setInt(setting.name, value);
    notifyListeners();
  }

  // Passing Through
  bool get debug => debugSettings.debug;
  set debug(bool value) => debugSettings.debug = value;

  FakeSummary get fakeSummary => debugSettings.fakeSummary;
  set fakeSummary(FakeSummary value) => debugSettings.fakeSummary = value;
}
