import 'package:carer/models/settings_cn.dart';
import 'package:carer/nsclient/summary.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum DebugSettingNames {
  debug,
  debugSummary,
}

enum DebugSummary {
  off(),
  normal(),
  low(),
  high();

  const DebugSummary();
  Summary summary() {
    switch (this) {
      case DebugSummary.off:
        return Summary.empty;
      case DebugSummary.normal:
        return highSummary();
      case DebugSummary.low:
        return highSummary();
      case DebugSummary.high:
        return highSummary();
    }
  }
}

class DebugSettings {
  SharedPreferences prefs;
  Function() notifyListeners;

  DebugSettings({required this.prefs, required this.notifyListeners});

  bool _debug = false;
  DebugSummary _debugSummary = DebugSummary.off;

  void populateDebugSettings() {
    var debugPref = prefs.getBool(DebugSettingNames.debug.name);
    if (debugPref != null) {
      _debug = debugPref;
    }

    var debugSummaryPref = prefs.getString(DebugSettingNames.debugSummary.name);
    if (debugSummaryPref != null) {
      _debugSummary = DebugSummary.values.firstWhere(
          (e) => e.name == debugSummaryPref,
          orElse: () => DebugSummary.off);
    }
  }

  bool get debug => _debug;
  set debug(bool value) {
    prefs.setBool(DebugSettingNames.debug.name, value);
    _debug = value;
    notifyListeners();
  }

  DebugSummary get debugSummary => _debugSummary;
  set debugSummary(DebugSummary value) {
    prefs.setString(DebugSettingNames.debugSummary.name, value.name);
    _debugSummary = value;
    notifyListeners();
  }
}

Summary highSummary() {
  return Summary(
      sgvs: SGVs(sgvs: [
        SGV(
            sgv: 180,
            mills: DateTime.now()..subtract(const Duration(minutes: 8))),
        SGV(
            sgv: 250,
            mills: DateTime.now()..subtract(const Duration(minutes: 4))),
      ]),
      tempBasals: Summary.empty.tempBasals,
      treatments: Summary.empty.treatments,
      targets: Summary.empty.targets,
      state: Summary.empty.state,
      profile: Summary.empty.profile,
      dateRetrievedmills: 10);
}
