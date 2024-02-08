import 'package:carer/models/settings_cn.dart';
import 'package:carer/nsclient/summary.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum DebugSettingNames {
  debug,
  fakeSummary,
}

enum FakeSummary {
  off(),
  normal(),
  low(),
  high();

  const FakeSummary();
  Summary summary() {
    switch (this) {
      case FakeSummary.off:
        return Summary.empty;
      case FakeSummary.normal:
        return highSummary();
      case FakeSummary.low:
        return highSummary();
      case FakeSummary.high:
        return highSummary();
    }
  }
}

class DebugSettings {
  SharedPreferences prefs;
  Function() notifyListeners;

  DebugSettings({required this.prefs, required this.notifyListeners});

  bool _debug = false;
  FakeSummary _fakeSummary = FakeSummary.off;

  void populateDebugSettings() {
    var debugPref = prefs.getBool(DebugSettingNames.debug.name);
    if (debugPref != null) {
      _debug = debugPref;
    }

    var fakeSummaryPref = prefs.getString(DebugSettingNames.fakeSummary.name);
    if (fakeSummaryPref != null) {
      _fakeSummary = FakeSummary.values.firstWhere(
          (e) => e.name == fakeSummaryPref,
          orElse: () => FakeSummary.off);
    }
  }

  bool get debug => _debug;
  set debug(bool value) {
    prefs.setBool(DebugSettingNames.debug.name, value);
    _debug = value;
    notifyListeners();
  }

  FakeSummary get fakeSummary => _fakeSummary;
  set fakeSummary(FakeSummary value) {
    prefs.setString(DebugSettingNames.fakeSummary.name, value.name);
    _fakeSummary = value;
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
            sgv: 200,
            mills: DateTime.now()..subtract(const Duration(minutes: 4))),
      ]),
      tempBasals: Summary.empty.tempBasals,
      treatments: Summary.empty.treatments,
      targets: Summary.empty.targets,
      state: Summary.empty.state,
      profile: Summary.empty.profile,
      dateRetrievedmills: 10);
}
