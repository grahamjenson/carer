import 'package:carer/models/constants.dart';
import 'package:carer/sql/key_value_store.dart';
import 'package:carer/utils/futures.dart';
import 'package:signals/signals_flutter.dart';

enum _UINames {
  screenActive,
  uiLayoutVertical,
  uiLayoutHorizontal,
  uiTheme,
  unit,
}

class UISettings {
  static final UISettings _singleton = UISettings._();
  factory UISettings() => _singleton;

  final Map<_UINames, Signal> _signals = {
    _UINames.screenActive: Signal<bool>(false, debugLabel: 'screenActive'),
    _UINames.uiLayoutVertical: Signal<UILayout>(UILayout.showBGL, debugLabel: 'uiLayoutVertical'),
    _UINames.uiLayoutHorizontal: Signal<UILayout>(UILayout.showBGL, debugLabel: 'uiLayoutHorizontal'),
    _UINames.uiTheme: Signal<UITheme>(UITheme.normal, debugLabel: 'uiTheme'),
    _UINames.unit: Signal<Unit>(Unit.mg, debugLabel: 'unit'),
  };

  UISettings._();

  bool get screenActive => _signals[_UINames.screenActive]!.value as bool;
  set screenActive(bool value) => _signals[_UINames.screenActive]!.value = value;

  UILayout get uiLayoutVertical => _signals[_UINames.uiLayoutVertical]!.value as UILayout;
  set uiLayoutVertical(UILayout value) => _signals[_UINames.uiLayoutVertical]!.value = value;

  UILayout get uiLayoutHorizontal => _signals[_UINames.uiLayoutHorizontal]!.value as UILayout;
  set uiLayoutHorizontal(UILayout value) => _signals[_UINames.uiLayoutHorizontal]!.value = value;

  UITheme get uiTheme => _signals[_UINames.uiTheme]!.value as UITheme;
  set uiTheme(UITheme value) => _signals[_UINames.uiTheme]!.value = value;

  Unit get unit => _signals[_UINames.unit]!.value as Unit;
  set unit(Unit value) => _signals[_UINames.unit]!.value = value;

  setupDBPropagation(KeyValueStore prefs) {
    // Assign the values from the DB
    screenActive = prefs.getBool(_UINames.screenActive.name, defaultValue: true)!;

    uiLayoutVertical = UILayout.fromString(prefs.getString(_UINames.uiLayoutVertical.name));

    uiLayoutHorizontal = UILayout.fromString(prefs.getString(_UINames.uiLayoutHorizontal.name));

    uiTheme = UITheme.fromString(prefs.getString(_UINames.uiTheme.name));

    unit = Unit.fromBool(prefs.getBool(_UINames.unit.name, defaultValue: true)!);

    // Setup DB sync for when signalls change

    aeffect(() => prefs.setBool(_UINames.unit.name, unit.toBool()));

    aeffect(() {
      prefs.setBool(_UINames.screenActive.name, screenActive);
    });

    aeffect(() {
      prefs.setString(_UINames.uiLayoutVertical.name, uiLayoutVertical.name);
    });

    aeffect(() {
      prefs.setString(_UINames.uiLayoutHorizontal.name, uiLayoutHorizontal.name);
    });

    aeffect(() {
      prefs.setString(_UINames.uiTheme.name, uiTheme.name);
    });
  }
}

enum UITheme {
  // NS Settings
  normal("Normal");

  final String viewName;

  const UITheme(this.viewName);

  static UITheme fromString(String? value) {
    return UITheme.values.firstWhere((e) => e.name == value, orElse: () => UITheme.normal);
  }
}

enum UILayout {
  // NS Settings
  showBGLChartHistoryStats("Everything"),
  showBGL("BGL");

  final String viewName;

  const UILayout(this.viewName);

  static UILayout fromString(String? value) {
    return UILayout.values.firstWhere((e) => e.name == value, orElse: () => UILayout.showBGL);
  }
}
