import 'package:carer/models/settings_cn.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum DebugSettingNames {
  debug,
  fakeSummary,
}

enum FakeSummary {
  off,
  normal,
  low,
  high,
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
