import 'package:carer/change_notifiers/settings_cn.dart';
import 'package:carer/nsclient/summary.dart';
import 'package:carer/sql/key_value_store.dart';

enum DebugSettingNames {
  debug,
  debugSummary,
  logErrors,
}

enum DebugSummary {
  off,
  low,
  normal,
  high;

  Summary? summary(SettingsCN settings) {
    switch (this) {
      case DebugSummary.off:
        return null;
      case DebugSummary.normal:
        return null;
      case DebugSummary.low:
        return null;
      case DebugSummary.high:
        return null;
    }
  }
}

class DebugSettings {
  KeyValueStore prefs;
  SettingsCN settings;

  DebugSettings({required this.prefs, required this.settings});

  bool get debug =>
      prefs.getBool(DebugSettingNames.debug.name, defaultValue: false)!;
  set debug(bool value) {
    prefs.setBool(DebugSettingNames.debug.name, value);

    settings.notify();
  }

  DebugSummary get debugSummary {
    var debugSummaryPref = prefs.getString(DebugSettingNames.debugSummary.name,
        defaultValue: DebugSummary.off.name);
    return DebugSummary.values.firstWhere((e) => e.name == debugSummaryPref,
        orElse: () => DebugSummary.off);
  }

  set debugSummary(DebugSummary value) {
    prefs.setString(DebugSettingNames.debugSummary.name, value.name);
    settings.notify();
  }

  bool get logErrors =>
      prefs.getBool(DebugSettingNames.logErrors.name, defaultValue: true)!;
  set logErrors(bool value) {
    prefs.setBool(DebugSettingNames.logErrors.name, value);

    settings.notify();
  }
}
