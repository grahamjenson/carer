import 'package:carer/models/profile.dart';
import 'package:carer/models/temptarget.dart';
import 'package:carer/models/valueAtTime.dart';
import 'package:carer/sql/carer_db.dart';
import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_utils.dart';

void main() async {
  await sqfliteTestInit();

  group('ValueAtTime', () {
    // TODO this will be flaky
    DateTime now = clock.now(); // cant stub out sqlite date (uses system datetime)
    DateTime nowMinPlus1 = DateTime(now.year, now.month, now.day, now.hour, now.minute + 1);
    DateTime nowMin = DateTime(now.year, now.month, now.day, now.hour, now.minute);
    DateTime now1Min = DateTime(now.year, now.month, now.day, now.hour, now.minute - 1);

    DateTime now2Min = DateTime(now.year, now.month, now.day, now.hour, now.minute - 2);

    setUp(() async {});

    tearDown(() async {
      await (await CarerDB.instance).deleteAll();
    });

    test("get values at time ", () async {
      var p = Profile(
        dia: 5,
        timezone: "asad",
        units: "mmol",
        date: now,
        carbratio: List<int>.filled(24, 1),
        sens: List<int>.filled(24, 1),
        basal: List<double>.filled(24, 1),
        targetLow: List<int>.filled(24, 1),
        targetHigh: List<int>.filled(24, 2),
      );
      expect(await p.save(), true);

      var targets = await ValueAtTime.query();

      expect(targets.length, 360); // 5 hours

      valueAssertion(targets[0], targetLow: 1, targetHigh: 2, isTempTarget: false, date: nowMin);

      valueAssertion(targets[1], targetLow: 1, targetHigh: 2, isTempTarget: false, date: now1Min);

      var s = await TempTarget(startDate: now.subtract(const Duration(seconds: 50)), duration: 300, targetHigh: 10, targetLow: 5).save();
      expect(s, true);

      targets = await ValueAtTime.query();
      expect(targets.length, 360);

      print("${targets[0]} ${targets[1]}");

      // beginning will be 1 hour ahead
      valueAssertion(targets[0], targetLow: 5, targetHigh: 10, isTempTarget: true, date: nowMin);

      // 3 days of profile targets + 1 temp target
      valueAssertion(targets[1], targetLow: 1, targetHigh: 2, isTempTarget: false, date: now1Min);
    });
  });
}

void valueAssertion(ValueAtTime v, {int? targetLow, int? targetHigh, bool? isTempTarget, DateTime? date}) {
  if (targetLow != null) expect(v.targetLow, targetLow);
  if (targetHigh != null) expect(v.targetHigh, targetHigh);
  if (isTempTarget != null) expect(v.isTempTarget, isTempTarget);
  if (date != null) expect(v.date, date);
}
