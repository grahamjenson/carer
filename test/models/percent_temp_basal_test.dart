import 'dart:convert';

import 'package:carer/mappers/ns/profile.dart';
import 'package:carer/mappers/ns/tempbasal.dart';
import 'package:carer/mappers/sql/tempbasal.dart';
import 'package:carer/models/sql/profile.dart';
import 'package:carer/models/sql/tempbasal.dart';
import 'package:carer/models/valueAtTime.dart';
import 'package:carer/nsclient/treatments.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_utils.dart';

Profile profile(String name, DateTime start, int durationSeconds, List<double> basal) => Profile(
      name: name,
      eid: name,
      dia: 5,
      source: NSProfileSource.defaultStoreProfile.name,
      percent: 100,
      duration: durationSeconds,
      timezone: "Pacific/Auckland",
      units: "mmol",
      startDate: start,
      carbratio: List<int>.filled(24, 10),
      sens: List<int>.filled(24, 50),
      basal: basal,
      lowTarget: List<int>.filled(24, 90),
      highTarget: List<int>.filled(24, 120),
    );

void main() {
  // As in the Loops session's run (C12): AAPS sends a percent temp basal with the rate it was at its start, and no
  // absolute rate
  test("AAPS's percent temp basal keeps its percent, and an absolute one has none", () {
    var date = DateTime(2020, 1, 1, 11, 30).millisecondsSinceEpoch;
    var treatments = NSTreatments.fromJson(jsonEncode({
      "result": [
        {"identifier": "tbr-percent", "eventType": "Temp Basal", "percent": 40, "rate": 1.68, "duration": 60, "date": date},
        {"identifier": "tbr-absolute", "eventType": "Temp Basal", "absolute": 0.5, "rate": 0.5, "duration": 60, "date": date + 1},
      ]
    }));
    var tempBasals = const NSTempBasalToTempBasal().mapAToB(treatments.tempBasals);
    var percent = tempBasals.firstWhere((t) => t.eid == "tbr-percent");
    expect((percent.value, percent.percent), (1.68, 40));
    var absolute = tempBasals.firstWhere((t) => t.eid == "tbr-absolute");
    expect((absolute.value, absolute.percent), (0.5, null));
  });

  test("a percent temp basal's rate is the profile's at each minute, across a profile switch's end and a basal block", () {
    // The default profile's basal is 1.0 U/h until 12:00, then 1.5; a switch to Night (2.0 U/h) from 11:00 to 11:45
    var basal = [for (var hour = 0; hour < 24; hour++) hour < 12 ? 1.0 : 1.5];
    var profiles = [profile("Default", DateTime(2019, 12, 1), 0, basal)];
    var switches = [profile("Night", DateTime(2020, 1, 1, 11), 45 * 60, List<double>.filled(24, 2.0))];
    var tbr140 = TempBasal(eid: "tbr", startDate: DateTime(2020, 1, 1, 11, 30), duration: 60 * 60, value: 2.8, percent: 40);

    double basalAt(int hour, int minute, List<TempBasal> tempBasals) =>
        ValueAtTime.createValueAtTime(profiles, switches, [], tempBasals, DateTime(2020, 1, 1, hour, minute)).basal;

    expect(basalAt(11, 40, [tbr140]), closeTo(2.8, 1e-9)); // Night's 2.0 at 140 %
    expect(basalAt(11, 50, [tbr140]), closeTo(1.4, 1e-9)); // Night ended: the default's 1.0 at 140 %
    expect(basalAt(12, 10, [tbr140]), closeTo(2.1, 1e-9)); // The default's next block, 1.5, at 140 %
    expect(basalAt(12, 40, [tbr140]), 1.5); // The temp basal ended

    // An absolute temp basal (Loop, careportal) is its rate, whatever the profile's
    var tbrAbsolute = TempBasal(eid: "tbr-abs", startDate: DateTime(2020, 1, 1, 11, 30), duration: 60 * 60, value: 0.5);
    expect(basalAt(11, 40, [tbrAbsolute]), 0.5);
    expect(basalAt(12, 10, [tbrAbsolute]), 0.5);
  });

  agroup("percent temp basal", () {
    atest("a percent temp basal is stored with its percent", () async {
      var tbr = TempBasal(eid: "tbr-stored", startDate: DateTime(2020, 1, 1, 11, 30), duration: 3600, value: 1.68, percent: 40);
      await SQLToTempBasal().upsertAll([tbr]);
      var stored = (await SQLToTempBasal().query(conditions: {"eid = ?": "tbr-stored"})).single;
      expect((stored.value, stored.percent), (1.68, 40));
    });
  });
}
