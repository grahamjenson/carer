import 'package:carer/models/sgv.dart';
import 'package:carer/sql/carer_db.dart';
import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_utils.dart';

void main() {
  sqfliteTestInit();

  group('SGV', () {
    DateTime now = DateTime(2020, 1, 1, 12);
    Duration min5 = const Duration(minutes: 5);
    Duration hour48 = const Duration(hours: 48);

    setUp(() async {});

    tearDown(() async {
      await (await CarerDB.instance).deleteAll();
    });

    test('lastMins', () async {
      expect(await SGV(value: 2, date: now.subtract(min5)).save(), true);
      expect(await SGV(value: 1, date: now).save(), true);

      await withClock(Clock.fixed(now), () async {
        var sgvs = await SGV.lastMins(1);
        expect(sgvs.length, 1);
        sgvs = await SGV.lastMins(10);
        expect(sgvs.length, 2);
      });
    });

    test("lastSGV", () async {
      var sgv = await SGV.lastSGV();
      expect(sgv, null);

      expect(await SGV(value: 2, date: now.subtract(min5)).save(), true);

      sgv = await SGV.lastSGV();
      expect(sgv!.value, 2);

      // Add more recent number

      expect(await SGV(value: 1, date: now).save(), true);

      sgv = await SGV.lastSGV();
      expect(sgv!.value, 1);
    });

    test("percentInRangeToday", () async {
      expect(await SGV(value: 2, date: now.subtract(hour48)).save(), true);
      expect(await SGV(value: 2, date: now.subtract(min5 + min5)).save(), true);
      expect(await SGV(value: 1, date: now.subtract(min5)).save(), true);

      await withClock(Clock.fixed(now), () async {
        var percent = await SGV.percentInRangeToday(0, 3);
        expect(percent, 1.0);
        percent = await SGV.percentInRangeToday(0, 1);
        expect(percent, 0.0);
        percent = await SGV.percentInRangeToday(1, 2);
        expect(percent, 0.5);
        percent = await SGV.percentInRangeToday(2, 3);
        expect(percent, 0.5);
      });
    });
  });
}
