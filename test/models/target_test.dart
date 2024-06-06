import 'package:carer/models/profile.dart';
import 'package:carer/models/target.dart';
import 'package:carer/models/temptarget.dart';
import 'package:carer/sql/carer_db.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_utils.dart';

void main() {
  sqfliteTestInit();

  group('Target', () {
    // TODO this will be flaky
    DateTime now =
        DateTime.now(); // cant stub out sqlite date (uses system datetime)
    DateTime nowMS = DateTime(now.year, now.month, now.day, now.hour,
        now.minute, now.second, now.millisecond);
    DateTime beginningOfHour = DateTime(now.year, now.month, now.day, now.hour);
    DateTime beginningOfHourPlus5 =
        DateTime(now.year, now.month, now.day, now.hour, 5);
    DateTime beginningOfNextHour =
        DateTime(now.year, now.month, now.day, now.hour + 1);

    setUp(() async {});

    tearDown(() async {
      await (await CarerDB.instance).deleteAll();
    });

    test("get targets ", () async {
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

      var targets = await Target.query(
          before: beginningOfNextHour.millisecondsSinceEpoch + 1);

      expect(targets.length, 73); // 3 days of targets + 1 hour ahead
      expect(targets[0].targetLow, 1);
      expect(targets[0].targetHigh, 2);
      expect(targets[0].isTempTarget, false);
      // This will be the latest change in targets
      expect(targets[0].date, beginningOfNextHour);

      expect(targets[1].targetLow, 1);
      expect(targets[1].targetHigh, 2);
      expect(targets[1].isTempTarget, false);
      expect(targets[1].date, beginningOfHour);

      var s = await TempTarget(
              startDate: beginningOfHourPlus5,
              duration: 300,
              targetHigh: 10,
              targetLow: 5)
          .save();
      expect(s, true);

      targets = await Target.query(
          before: beginningOfNextHour.millisecondsSinceEpoch + 1);
      expect(targets.length, 73 + 2);

      // beginning will be 1 hour ahead
      expect(targets[0].targetLow, 1);
      expect(targets[0].targetHigh, 2);
      expect(targets[0].isTempTarget, false);
      expect(targets[0].date, beginningOfNextHour);

      // 3 days of profile targets + 1 temp target

      expect(targets[1].targetLow, 1);
      expect(targets[1].targetHigh, 2);
      expect(targets[1].isTempTarget, false);
      // This will be the latest change in targets
      expect(targets[1].date,
          beginningOfHourPlus5.add(const Duration(seconds: 300)));

      expect(targets[2].targetLow, 5);
      expect(targets[2].targetHigh, 10);
      expect(targets[2].isTempTarget, true);
      expect(targets[2].date, beginningOfHourPlus5);

      expect(targets[3].targetLow, 1);
      expect(targets[3].targetHigh, 2);
      expect(targets[3].isTempTarget, false);
      expect(targets[3].date, beginningOfHour);
    });
  });
}
