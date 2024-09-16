import 'package:carer/models/constants.dart';
import 'package:carer/sql/key_value_store.dart';
import 'package:carer/utils/futures.dart';

enum _UINames {
  unit,
  screenActive,
}

enum UITheme {
  // NS Settings
  normal("Normal"),
  dim("Dim");

  final String viewName;

  const UITheme(this.viewName);

  static UITheme fromString(String? value) {
    return UITheme.values.firstWhere((e) => e.name == value, orElse: () => UITheme.normal);
  }
}

enum UILayout {
  // NS Settings
  showBGLChartHistoryStats("Everything"),
  showBGL("BGL"),
  showMinimal("Minimal");

  final String viewName;

  const UILayout(this.viewName);

  static UILayout fromString(String? value) {
    return UILayout.values.firstWhere((e) => e.name == value, orElse: () => UILayout.showBGL);
  }
}

enum ThemeLayout {
  mainUI,
  alarmUI,
  nightUI,
}

class UIThemeLayout {
  final String baseName;
  late ASignal<UITheme> themeSignal;
  late ASignal<UILayout> horizonalLayoutSignal;
  late ASignal<UILayout> verticalLayoutSignal;
  late ASignal<bool> enabledSignal;

  UIThemeLayout(this.baseName) {
    enabledSignal = ASignal<bool>(true, debugLabel: enabledPref);
    themeSignal = ASignal<UITheme>(UITheme.normal, debugLabel: themePref);
    horizonalLayoutSignal = ASignal<UILayout>(UILayout.showBGL, debugLabel: horizonalLayoutPref);
    verticalLayoutSignal = ASignal<UILayout>(UILayout.showBGL, debugLabel: verticalLayoutPref);
  }

  List<ASignal> get signals => [enabledSignal, themeSignal, horizonalLayoutSignal, verticalLayoutSignal];

  String get enabledPref => "${baseName}Enabled";
  bool get enabled => enabledSignal.value;
  set enabled(bool value) => enabledSignal.value = value;

  String get themePref => "${baseName}Theme";
  UITheme get theme => themeSignal.value;
  set theme(UITheme value) => themeSignal.value = value;

  String get horizonalLayoutPref => "${baseName}HorizonalLayout";
  UILayout get horizonalLayout => horizonalLayoutSignal.value;
  set horizonalLayout(UILayout value) => horizonalLayoutSignal.value = value;

  String get verticalLayoutPref => "${baseName}VerticalLayout";
  UILayout get verticalLayout => verticalLayoutSignal.value;
  set verticalLayout(UILayout value) => verticalLayoutSignal.value = value;

  setup(KeyValueStore prefs) {
    enabled = prefs.getBool(enabledPref, defaultValue: true)!;
    theme = UITheme.fromString(prefs.getString(themePref));
    horizonalLayout = UILayout.fromString(prefs.getString(horizonalLayoutPref));
    verticalLayout = UILayout.fromString(prefs.getString(verticalLayoutPref));

    aeffect(() {
      prefs.setBool(enabledPref, enabled);
    }, debugLabel: enabledPref);

    aeffect(() {
      prefs.setString(themePref, theme.name);
    }, debugLabel: themePref);

    aeffect(() {
      prefs.setString(horizonalLayoutPref, horizonalLayout.name);
    }, debugLabel: horizonalLayoutPref);

    aeffect(() {
      prefs.setString(verticalLayoutPref, verticalLayout.name);
    }, debugLabel: verticalLayoutPref);
  }
}

class UISettings {
  static final UISettings _singleton = UISettings._();
  factory UISettings() => _singleton;

  final Map<_UINames, ASignal> _signals = {
    _UINames.screenActive: ASignal<bool>(false, debugLabel: 'screenActive'),
    _UINames.unit: ASignal<Unit>(Unit.mg, debugLabel: 'unit'),
  };

  Map<ThemeLayout, UIThemeLayout> themeLayouts = {
    ThemeLayout.mainUI: UIThemeLayout(ThemeLayout.mainUI.name),
    ThemeLayout.alarmUI: UIThemeLayout(ThemeLayout.alarmUI.name),
    ThemeLayout.nightUI: UIThemeLayout(ThemeLayout.nightUI.name),
  };

  List<ASignal> get themeLayoutSignals => themeLayouts.values.expand((e) => e.signals).toList();
  UIThemeLayout get mainUIThemeLayout => themeLayouts[ThemeLayout.mainUI]!;
  UIThemeLayout get alarmUIThemeLayout => themeLayouts[ThemeLayout.alarmUI]!;
  UIThemeLayout get nightUIThemeLayout => themeLayouts[ThemeLayout.nightUI]!;

  UISettings._();

  bool get screenActive => _signals[_UINames.screenActive]!.value as bool;
  set screenActive(bool value) => _signals[_UINames.screenActive]!.value = value;

  Unit get unit => _signals[_UINames.unit]!.value as Unit;
  set unit(Unit value) => _signals[_UINames.unit]!.value = value;

  setupDBPropagation(KeyValueStore prefs) {
    // Assign the values from the DB
    screenActive = prefs.getBool(_UINames.screenActive.name, defaultValue: true)!;

    unit = Unit.fromBool(prefs.getBool(_UINames.unit.name, defaultValue: true)!);

    for (var themeLayout in themeLayouts.values) {
      themeLayout.setup(prefs);
    }
    // Setup DB sync for when signalls change

    aeffect(() => prefs.setBool(_UINames.unit.name, unit.toBool()), debugLabel: _UINames.unit.name);

    aeffect(() {
      prefs.setBool(_UINames.screenActive.name, screenActive);
    }, debugLabel: _UINames.screenActive.name);
  }
}
