import 'package:carer/models/settings_cn.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

enum UISettingsNames { screenActive, showHistory }

class UISettings {
  SharedPreferences prefs;
  Settings settings;

  bool _screenActive = true;
  bool _showHistory = true;

  UISettings({required this.prefs, required this.settings});

  void populate() {
    var screenActivePref = prefs.getBool(UISettingsNames.screenActive.name);
    if (screenActivePref != null) {
      _screenActive = screenActivePref;
    }

    var showHistoryPref = prefs.getBool(UISettingsNames.showHistory.name);
    if (showHistoryPref != null) {
      _showHistory = showHistoryPref;
    }
  }

  // Screen Active
  bool get screenActive => _screenActive;
  set screenActive(bool value) {
    prefs.setBool(UISettingsNames.screenActive.name, value);
    _screenActive = value;
    WakelockPlus.toggle(enable: value);
    settings.notifyListeners();
  }

  // ShowHistory
  bool get showHistory => _showHistory;
  set showHistory(bool value) {
    prefs.setBool(UISettingsNames.showHistory.name, value);
    _showHistory = value;
    settings.notifyListeners();
  }
}
