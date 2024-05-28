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
      var sgvCount = await SGV.createOrUpdate([
        SGV(value: 2, date: now.subtract(min5)),
        SGV(value: 1, date: now),
      ]);
      expect(sgvCount, 2);

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

      var sgvCount = await SGV.createOrUpdate([
        SGV(value: 2, date: now.subtract(min5)),
      ]);
      expect(sgvCount, 1);

      sgv = await SGV.lastSGV();
      expect(sgv!.value, 2);

      // Add more recent number
      sgvCount = await SGV.createOrUpdate([
        SGV(value: 1, date: now),
      ]);
      expect(sgvCount, 1);
      sgv = await SGV.lastSGV();
      expect(sgv!.value, 1);
    });

    test("percentInRangeToday", () async {
      var sgvCount = await SGV.createOrUpdate([
        SGV(value: 2, date: now.subtract(hour48)),
        SGV(value: 2, date: now.subtract(min5 + min5)),
        SGV(value: 1, date: now.subtract(min5)),
      ]);
      expect(sgvCount, 3);

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
