import 'package:carer/models/sgv.dart';
import 'package:carer/sql/carer_db.dart';
import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_utils.dart';

void main() {
  sqfliteTestInit();

  group('SGV', () {
    DateTime now = DateTime(2020);
    Duration min5 = const Duration(minutes: 5);

    setUp(() async {});

    tearDown(() async {
      await (await CarerDB.instance).recreate();
    });

    test('lastMins', () async {
      var sgvCount = await SGV.createOrUpdateSGVs([
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

      var sgvCount = await SGV.createOrUpdateSGVs([
        SGV(value: 2, date: now.subtract(min5)),
      ]);
      expect(sgvCount, 1);

      sgv = await SGV.lastSGV();
      expect(sgv!.value, 2);

      // Add more recent number
      sgvCount = await SGV.createOrUpdateSGVs([
        SGV(value: 1, date: now),
      ]);
      expect(sgvCount, 1);
      sgv = await SGV.lastSGV();
      expect(sgv!.value, 1);
    });
  });
}
