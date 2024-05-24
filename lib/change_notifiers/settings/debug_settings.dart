import 'package:carer/change_notifiers/settings_cn.dart';
import 'package:carer/nsclient/summary.dart';
import 'package:carer/sql/key_value_store.dart';
import 'package:clock/clock.dart';

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

  Summary summary(SettingsCN settings) {
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

var counter = 0;

Summary highSummary(SettingsCN settings) {
  var start = settings.targetHigh - 6;
  var end = 15 * 18;
  counter += 6;
  if (counter > end || counter < start) {
    counter = start;
  }

  return Summary(
      raw: "",
      sgvs: SummarySGVs(sgvs: [
        SummarySGV(
            sgv: counter ~/ 1.1,
            mills: clock.now()..subtract(const Duration(minutes: 10))),
        SummarySGV(
            sgv: counter,
            mills: clock.now()..subtract(const Duration(minutes: 4))),
      ]),
      tempBasals: Summary.empty.tempBasals,
      treatments: Summary.empty.treatments,
      targets: Summary.empty.targets,
      state: Summary.empty.state,
      profile: Summary.empty.profile,
      dateRetrievedmills: 10);
}

Summary lowSummary(SettingsCN settings) {
  var start = settings.urgentLow - 18;
  var end = settings.targetLow + 18;
  counter -= 6;
  if (counter > end || counter < start) {
    counter = end;
  }

  return Summary(
      raw: "",
      sgvs: SummarySGVs(sgvs: [
        SummarySGV(
            sgv: counter ~/ 0.7,
            mills: clock.now()..subtract(const Duration(minutes: 30))),
        SummarySGV(sgv: counter, mills: clock.now()),
      ]),
      tempBasals: Summary.empty.tempBasals,
      treatments: Summary.empty.treatments,
      targets: Summary.empty.targets,
      state: Summary.empty.state,
      profile: Summary.empty.profile,
      dateRetrievedmills: 10);
}

Summary normalSummary(SettingsCN settings) {
  var start = settings.targetLow - 18;
  var end = settings.targetHigh + 18;
  counter += 6;
  if (counter > end || counter < start) {
    counter = start;
  }

  return Summary(
      raw: "",
      sgvs: SummarySGVs(sgvs: [
        SummarySGV(
            sgv: counter ~/ 1.1,
            mills: clock.now()..subtract(const Duration(minutes: 8))),
        SummarySGV(
            sgv: counter,
            mills: clock.now()..subtract(const Duration(minutes: 4))),
      ]),
      tempBasals: Summary.empty.tempBasals,
      treatments: Summary.empty.treatments,
      targets: Summary.empty.targets,
      state: Summary.empty.state,
      profile: Summary.empty.profile,
      dateRetrievedmills: 10);
}
