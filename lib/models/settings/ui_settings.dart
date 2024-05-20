import 'package:carer/models/settings_cn.dart';
import 'package:carer/sql/key_value_store.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

enum UISettingsNames {
  screenActive,
  uiLayoutVertical,
  uiLayoutHorizontal,
  uiTheme
}

enum UITheme {
  // NS Settings
  normal("Normal");

  final String viewName;

  const UITheme(this.viewName);
}

enum UILayout {
  // NS Settings
  showBGLChartHistoryStats("Everything"),
  showBGL("BGL");

  final String viewName;

  const UILayout(this.viewName);
}

class UISettings {
  KeyValueStore prefs;
  Settings settings;

  bool _screenActive = true;
  UILayout _uiLayoutVertical = UILayout.showBGL;
  UILayout _uiLayoutHorizontal = UILayout.showBGL;
  UITheme _uiTheme = UITheme.normal;
  UISettings({required this.prefs, required this.settings});

  void populate() {
    var screenActivePref = prefs.getBool(UISettingsNames.screenActive.name);
    if (screenActivePref != null) {
      _screenActive = screenActivePref;
    }

    var uiLayoutVerticalPref =
        prefs.getString(UISettingsNames.uiLayoutVertical.name);
    if (uiLayoutVerticalPref != null) {
      _uiLayoutVertical = UILayout.values.firstWhere(
          (e) => e.name == uiLayoutVerticalPref,
          orElse: () => UILayout.showBGL);
    }

    var uiLayoutHorizontalPref =
        prefs.getString(UISettingsNames.uiLayoutHorizontal.name);
    if (uiLayoutHorizontalPref != null) {
      _uiLayoutHorizontal = UILayout.values.firstWhere(
          (e) => e.name == uiLayoutHorizontalPref,
          orElse: () => UILayout.showBGL);
    }

    var uiThemePref = prefs.getString(UISettingsNames.uiTheme.name);
    if (uiThemePref != null) {
      _uiTheme = UITheme.values.firstWhere((e) => e.name == uiThemePref,
          orElse: () => UITheme.normal);
    }
  }

  // Screen Active
  bool get screenActive => _screenActive;
  set screenActive(bool value) {
    prefs.setBool(UISettingsNames.screenActive.name, value);
    _screenActive = value;
    WakelockPlus.toggle(enable: value);
    settings.notify();
  }

  // UI Layout Vertical
  UILayout get uiLayoutVertical => _uiLayoutVertical;
  set uiLayoutVertical(UILayout value) {
    prefs.setString(UISettingsNames.uiLayoutVertical.name, value.name);
    _uiLayoutVertical = value;
    settings.notify();
  }

  // UI Layout Horizontal
  UILayout get uiLayoutHorizontal => _uiLayoutHorizontal;
  set uiLayoutHorizontal(UILayout value) {
    prefs.setString(UISettingsNames.uiLayoutHorizontal.name, value.name);
    _uiLayoutHorizontal = value;
    settings.notify();
  }

  // UI Theme
  UITheme get uiTheme => _uiTheme;
  set uiTheme(UITheme value) {
    prefs.setString(UISettingsNames.uiTheme.name, value.name);
    _uiTheme = value;
    settings.notify();
  }
}
