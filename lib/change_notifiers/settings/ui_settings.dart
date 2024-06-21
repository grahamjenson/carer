import 'dart:async';

import 'package:carer/change_notifiers/settings_cn.dart';
import 'package:carer/sql/key_value_store.dart';
import 'package:signals/signals_flutter.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

enum UISettings {
  screenActive,
  uiLayoutVertical,
  uiLayoutHorizontal,
  uiTheme;

  Signal get signal {
    return settingsUISignals[this]!;
  }

  set value(dynamic value) {
    settingsUISignals[this]!.value = value;
  }

  get value {
    return settingsUISignals[this]!.value;
  }
}

Map<UISettings, Signal> settingsUISignals = {};

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

class UISettingsCN {
  KeyValueStore prefs;
  SettingsCN settings;

  UISettingsCN({required this.prefs, required this.settings}) {
    // Sometimes the app "forgets" that it is meant to keep the screen active

    // Assign the value of the settings from the KVStore
    var screenActive =
        prefs.getBool(UISettings.screenActive.name, defaultValue: true)!;

    settingsUISignals = {
      UISettings.screenActive: Signal<bool>(screenActive),
      UISettings.uiLayoutVertical: Signal<UILayout>(_uiLayoutVertical),
      UISettings.uiLayoutHorizontal: Signal<UILayout>(_uiLayoutHorizontal),
      UISettings.uiTheme: Signal<UITheme>(_uiTheme),
    };

    // On Signal change update the KVStore
    effect(() {
      var value = UISettings.screenActive.signal.value;
      prefs.setBool(UISettings.screenActive.name, value);
      WakelockPlus.toggle(enable: value);
    });

    effect(() {
      prefs.setString(
          UISettings.uiLayoutVertical.name, UISettings.uiLayoutVertical.name);
    });

    effect(() {
      prefs.setString(UISettings.uiLayoutHorizontal.name,
          (UISettings.uiLayoutHorizontal.signal.value as UILayout).name);
    });

    effect(() {
      var value = UISettings.uiTheme.signal.value as UITheme;
      prefs.setString(UISettings.uiTheme.name, value.name);
    });

    Timer.periodic(
        const Duration(seconds: 15),
        (Timer t) =>
            WakelockPlus.toggle(enable: UISettings.screenActive.signal.value));
  }

  // UI Layout Vertical
  UILayout get _uiLayoutVertical {
    var layout = prefs.getString(UISettings.uiLayoutVertical.name,
        defaultValue: UILayout.showBGL.name);

    return UILayout.values
        .firstWhere((e) => e.name == layout, orElse: () => UILayout.showBGL);
  }

  // UI Layout Horizontal
  UILayout get _uiLayoutHorizontal {
    var layout = prefs.getString(UISettings.uiLayoutHorizontal.name,
        defaultValue: UILayout.showBGL.name);

    return UILayout.values
        .firstWhere((e) => e.name == layout, orElse: () => UILayout.showBGL);
  }

  // UI Theme
  UITheme get _uiTheme {
    var uiThemePref = prefs.getString(UISettings.uiTheme.name);

    return UITheme.values
        .firstWhere((e) => e.name == uiThemePref, orElse: () => UITheme.normal);
  }
}
