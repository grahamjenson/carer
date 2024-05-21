import 'dart:async';

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

  UISettings({required this.prefs, required this.settings}) {
    // Sometimes the app "forgets" that it is meant to keep the screen active
    Timer.periodic(const Duration(seconds: 30),
        (Timer t) => WakelockPlus.toggle(enable: screenActive));
  }

  // Screen Active
  bool get screenActive =>
      prefs.getBool(UISettingsNames.screenActive.name, defaultValue: true)!;
  set screenActive(bool value) {
    prefs.setBool(UISettingsNames.screenActive.name, value);
    WakelockPlus.toggle(enable: value);
    settings.notify();
  }

  // UI Layout Vertical
  UILayout get uiLayoutVertical {
    var layout = prefs.getString(UISettingsNames.uiLayoutVertical.name,
        defaultValue: UILayout.showBGL.name);

    return UILayout.values
        .firstWhere((e) => e.name == layout, orElse: () => UILayout.showBGL);
  }

  set uiLayoutVertical(UILayout value) {
    prefs.setString(UISettingsNames.uiLayoutVertical.name, value.name);
    settings.notify();
  }

  // UI Layout Horizontal
  UILayout get uiLayoutHorizontal {
    var layout = prefs.getString(UISettingsNames.uiLayoutHorizontal.name,
        defaultValue: UILayout.showBGL.name);

    return UILayout.values
        .firstWhere((e) => e.name == layout, orElse: () => UILayout.showBGL);
  }

  set uiLayoutHorizontal(UILayout value) {
    prefs.setString(UISettingsNames.uiLayoutHorizontal.name, value.name);
    settings.notify();
  }

  // UI Theme
  UITheme get uiTheme {
    var uiThemePref = prefs.getString(UISettingsNames.uiTheme.name);

    return UITheme.values
        .firstWhere((e) => e.name == uiThemePref, orElse: () => UITheme.normal);
  }

  set uiTheme(UITheme value) {
    prefs.setString(UISettingsNames.uiTheme.name, value.name);

    settings.notify();
  }
}
