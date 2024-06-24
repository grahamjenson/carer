import 'dart:async';
import 'dart:io';

import 'package:carer/sql/key_value_store.dart';
import 'package:signals/signals_flutter.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

enum UISettings {
  screenActive,
  uiLayoutVertical,
  uiLayoutHorizontal,
  uiTheme;

  Signal get _signal {
    return _settingsSignals[this]!;
  }

  set value(dynamic value) {
    _settingsSignals[this]!.value = value;
  }

  get value {
    return _settingsSignals[this]!.value;
  }
}

Map<UISettings, Signal> _settingsSignals = {};

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

  UISettingsCN({required this.prefs}) {
    // Assign the value of the settings from the KVStore
    var screenActive =
        prefs.getBool(UISettings.screenActive.name, defaultValue: true)!;

    _settingsSignals = {
      UISettings.screenActive: Signal<bool>(screenActive),
      UISettings.uiLayoutVertical: Signal<UILayout>(_uiLayoutVertical),
      UISettings.uiLayoutHorizontal: Signal<UILayout>(_uiLayoutHorizontal),
      UISettings.uiTheme: Signal<UITheme>(_uiTheme),
    };

    // On Signal change update the KVStore
    effect(() {
      var value = UISettings.screenActive._signal.value;
      prefs.setBool(UISettings.screenActive.name, value);
      if (!Platform.environment.containsKey('FLUTTER_TEST')) {
        WakelockPlus.toggle(enable: value);
      }
    });

    effect(() {
      prefs.setString(UISettings.uiLayoutVertical.name,
          (UISettings.uiLayoutVertical._signal.value as UILayout).name);
    });

    effect(() {
      prefs.setString(UISettings.uiLayoutHorizontal.name,
          (UISettings.uiLayoutHorizontal._signal.value as UILayout).name);
    });

    effect(() {
      var value = UISettings.uiTheme._signal.value as UITheme;
      prefs.setString(UISettings.uiTheme.name, value.name);
    });

    Timer.periodic(
        const Duration(seconds: 15),
        (Timer t) =>
            WakelockPlus.toggle(enable: UISettings.screenActive._signal.value));
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
