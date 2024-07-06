import 'package:carer/models/sgv.dart';
import 'package:carer/predictors/sgv_predictors.dart';
import 'package:carer/sql/carer_db.dart';
import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_utils.dart';

void main() async {
  await sqfliteTestInit();

  DateTime now = DateTime(2020, 1, 1, 12);

  DateTime min5ago = now.subtract(const Duration(minutes: 5));
  DateTime min10ago = now.subtract(const Duration(minutes: 10));
  DateTime min15ago = now.subtract(const Duration(minutes: 15));
  DateTime min20ago = now.subtract(const Duration(minutes: 20));

  DateTime min5fromNow = now.add(const Duration(minutes: 5));
  DateTime min10fromNow = now.add(const Duration(minutes: 10));

  group('Linear Prediction', () {
    setUp(() async {
      // Will make a linear drop
      expect(await SGV(value: 140, date: now, eid: "1").save(), true);
      expect(await SGV(value: 150, date: min5ago, eid: "2").save(), true);
      expect(await SGV(value: 160, date: min10ago, eid: "3").save(), true);
      expect(await SGV(value: 170, date: min15ago, eid: "4").save(), true);
      expect(await SGV(value: 180, date: min20ago, eid: "5").save(), true);
    });

    tearDown(() async {
      await (await CarerDB.instance).deleteAll();
    });

    test("Linear2Predictor", () async {
      withClock(Clock.fixed(now), () async {
        await SGV.last3Hours.future;

        Linear2Predictor pr = Linear2Predictor();
        await pr.init();

        var sgvs = pr.predictNextHour();

        expect(sgvs.length, 60);

        var firstSGV = sgvs[4];
        var secondSGV = sgvs[9];
        expect(firstSGV.value, 130);
        expect(firstSGV.date, min5fromNow);
        expect(secondSGV.value, 120);
        expect(secondSGV.date, min10fromNow);
      });
    });
  });
}
