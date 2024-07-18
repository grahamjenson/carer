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

    test("getvaluesattime", () async {
      var p = Profile(
        name: "Default",
        eid: "EID",
        dia: 5,
        source: "Test",
        percent: 100,
        duration: 0,
        timezone: "asad",
        units: "mmol",
        startDate: now,
        carbratio: List<int>.filled(24, 1),
        sens: List<int>.filled(24, 1),
        basal: List<double>.filled(24, 1),
        lowTarget: List<int>.filled(24, 1),
        highTarget: List<int>.filled(24, 2),
      );
      expect(await p.save(), true);

      var targets = await ValueAtTime.query();

      expect(targets.length, 360); // 5 hours

      valueAssertion(targets[0], lowTarget: 1, highTarget: 2, isTempTarget: false, date: nowMin);

      valueAssertion(targets[1], lowTarget: 1, highTarget: 2, isTempTarget: false, date: now1Min);

      var s = await TempTarget(
        startDate: now.subtract(
          const Duration(minutes: 1),
        ),
        duration: 300,
        highTarget: 10,
        lowTarget: 5,
        eid: "1",
      ).save();
      expect(s, true);

      targets = await ValueAtTime.query();
      //print(targets.sublist(0, 5));
      expect(targets.length, 360);

      // beginning will be 1 hour ahead
      valueAssertion(targets[0], lowTarget: 5, highTarget: 10, isTempTarget: true, date: nowMin);

      // 3 days of profile targets + 1 temp target
      valueAssertion(targets[1], lowTarget: 1, highTarget: 2, isTempTarget: false, date: now1Min);
    });
  });
}

void valueAssertion(ValueAtTime v, {int? lowTarget, int? highTarget, bool? isTempTarget, DateTime? date}) {
  if (isTempTarget != null) expect(v.isTempTarget, isTempTarget);
  if (lowTarget != null) expect(v.lowTarget, lowTarget);
  if (highTarget != null) expect(v.highTarget, highTarget);

  if (date != null) expect(v.date, date);
}
