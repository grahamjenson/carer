import 'package:carer/models/debug_settings.dart';
import 'package:carer/models/target_settings.dart';
import 'package:carer/utils/math.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum SettingNames {
  // NS Settings
  nightscoutUrl,

  // Unit for BGL
  unit,

  // App settings
  screenActive,
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
  late TargetSettings targetSettings;

  String _nightscoutURL = '';
  Unit _unit = Unit.mmol;
  bool _screenActive = true;

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

    var screenActivePref = prefs.getBool(SettingNames.screenActive.name);
    if (screenActivePref != null) {
      _screenActive = screenActivePref;
    }

    targetSettings = TargetSettings(prefs: prefs, settings: this);
    targetSettings.populate();

    debugSettings = DebugSettings(prefs: prefs, settings: this);
    debugSettings.populate();
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
    prefs.setBool(SettingNames.screenActive.name, value);
    _screenActive = value;
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
