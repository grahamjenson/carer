import 'package:carer/models/settings_cn.dart';
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

  Summary summary(Settings settings) {
    switch (this) {
      case DebugSummary.off:
        return Summary.empty;
      case DebugSummary.normal:
        return normalSummary(settings);
      case DebugSummary.low:
        return lowSummary(settings);
      case DebugSummary.high:
        return highSummary(settings);
    }
  }
}

class DebugSettings {
  KeyValueStore prefs;
  Settings settings;

  DebugSettings({required this.prefs, required this.settings});

  bool _debug = false;
  bool _logErrors = true;

  DebugSummary _debugSummary = DebugSummary.off;

  void populate() {
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

    var logErrorsPref = prefs.getBool(DebugSettingNames.logErrors.name);
    if (logErrorsPref != null) {
      _logErrors = logErrorsPref;
    }
  }

  bool get debug => _debug;
  set debug(bool value) {
    prefs.setBool(DebugSettingNames.debug.name, value);
    _debug = value;
    settings.notify();
  }

  DebugSummary get debugSummary => _debugSummary;
  set debugSummary(DebugSummary value) {
    prefs.setString(DebugSettingNames.debugSummary.name, value.name);
    _debugSummary = value;
    settings.notify();
  }

  bool get logErrors => _logErrors;
  set logErrors(bool value) {
    prefs.setBool(DebugSettingNames.logErrors.name, value);
    _logErrors = value;
    settings.notify();
  }
}

var counter = 0;

Summary highSummary(Settings settings) {
  var start = settings.targetHigh - 6;
  var end = 15 * 18;
  counter += 6;
  if (counter > end || counter < start) {
    counter = start;
  }

  return Summary(
      raw: "",
      sgvs: SGVs(sgvs: [
        SGV(
            sgv: counter ~/ 1.1,
            mills: DateTime.now()..subtract(const Duration(minutes: 10))),
        SGV(
            sgv: counter,
            mills: DateTime.now()..subtract(const Duration(minutes: 4))),
      ]),
      tempBasals: Summary.empty.tempBasals,
      treatments: Summary.empty.treatments,
      targets: Summary.empty.targets,
      state: Summary.empty.state,
      profile: Summary.empty.profile,
      dateRetrievedmills: 10);
}

Summary lowSummary(Settings settings) {
  var start = settings.urgentLow - 18;
  var end = settings.targetLow + 18;
  counter -= 6;
  if (counter > end || counter < start) {
    counter = end;
  }

  return Summary(
      raw: "",
      sgvs: SGVs(sgvs: [
        SGV(
            sgv: counter ~/ 0.7,
            mills: DateTime.now()..subtract(const Duration(minutes: 30))),
        SGV(sgv: counter, mills: DateTime.now()),
      ]),
      tempBasals: Summary.empty.tempBasals,
      treatments: Summary.empty.treatments,
      targets: Summary.empty.targets,
      state: Summary.empty.state,
      profile: Summary.empty.profile,
      dateRetrievedmills: 10);
}

Summary normalSummary(Settings settings) {
  var start = settings.targetLow - 18;
  var end = settings.targetHigh + 18;
  counter += 6;
  if (counter > end || counter < start) {
    counter = start;
  }

  return Summary(
      raw: "",
      sgvs: SGVs(sgvs: [
        SGV(
            sgv: counter ~/ 1.1,
            mills: DateTime.now()..subtract(const Duration(minutes: 8))),
        SGV(
            sgv: counter,
            mills: DateTime.now()..subtract(const Duration(minutes: 4))),
      ]),
      tempBasals: Summary.empty.tempBasals,
      treatments: Summary.empty.treatments,
      targets: Summary.empty.targets,
      state: Summary.empty.state,
      profile: Summary.empty.profile,
      dateRetrievedmills: 10);
}
