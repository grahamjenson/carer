import 'package:carer/models/profile.dart';
import 'package:carer/nsclient/summary.dart';
import 'package:carer/sql/carer_db.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_utils.dart';

void main() {
  sqfliteTestInit();

  const SummaryProfile emptySummaryProfile = SummaryProfile(
      dia: 1,
      carbratio: TimeValues(values: []),
      sens: TimeValues(values: []),
      basal: TimeValues(values: []),
      targetLow: TimeValues(values: []),
      targetHigh: TimeValues(values: []),
      units: "",
      timezone: "");

  group('Profile', () {
    DateTime now = DateTime(2020, 1, 1, 12);
    Duration min5 = const Duration(minutes: 5);
    Duration hour48 = const Duration(hours: 48);

    setUp(() async {});

    tearDown(() async {
      await (await CarerDB.instance).deleteAll();
    });

    test("create", () async {
      var p = Profile(
        dia: 5,
        timezone: "asad",
        units: "mmol",
        date: now,
        carbratio: List<int>.filled(24, 1),
        sens: List<int>.filled(24, 1),
        basal: List<double>.filled(24, 1),
        targetLow: List<int>.filled(24, 1),
        targetHigh: List<int>.filled(24, 1),
      );
      expect(await p.save(), true);

      var p1 = await Profile.profile();
      expect(p1, isNotNull);
    });

    test("does not create", () async {
      print(emptySummaryProfile.expandedCarbratio());
      var p = Profile(
        date: now,
        dia: emptySummaryProfile.dia,
        units: emptySummaryProfile.units,
        timezone: emptySummaryProfile.timezone,
        carbratio: emptySummaryProfile.expandedCarbratio(),
        sens: emptySummaryProfile.expandedSens(),
        basal: emptySummaryProfile.expandedBasal(),
        targetLow: emptySummaryProfile.expandedTargetLow(),
        targetHigh: emptySummaryProfile.expandedTargetHigh(),
      );
      var profileSave = await p.save();

      expect(profileSave, true);

      var p1 = await Profile.count();
      expect(p1, 0);
    });
  });
}
