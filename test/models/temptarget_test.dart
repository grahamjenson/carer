import 'package:carer/mappers/sql_mappers.dart';
import 'package:carer/models/temptarget.dart';
import 'package:carer/sql/carer_db.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_utils.dart';

void main() async {
  await sqfliteTestInit();

  group('Temptargets', () {
    DateTime now = DateTime(2020, 1, 1, 12);
    Duration min1 = const Duration(minutes: 1);
    Duration min5 = const Duration(minutes: 5);
    Duration hour48 = const Duration(hours: 48);

    setUp(() async {});

    tearDown(() async {
      await (await CarerDB.instance).deleteAll();
    });

    test("createAndupdate", () async {
      var tt1 = TempTarget(
        startDate: now.add(min5),
        duration: 60,
        lowTarget: 100,
        highTarget: 120,
        eid: "1",
      );
      expect(await SQLToTempTarget().upsertAll([tt1]), true);

      var ttl1 = await TempTarget.query();
      expect(ttl1.length, 1);
      var id = ttl1[0].id;
      expect(tt1.id, id);
      expect(ttl1[0].id, id);
      expect(ttl1[0].startDate, now.add(min5));
      expect(ttl1[0].lowTarget, 100);
      expect(ttl1[0].highTarget, 120);
      expect(ttl1[0].duration, 60);

      var tt2 = TempTarget(
        startDate: now.add(min5),
        duration: 30,
        lowTarget: 100,
        highTarget: 120,
        eid: "1",
      );
      expect(await SQLToTempTarget().upsertAll([tt2]), true);

      var ttl2 = await TempTarget.query();
      expect(ttl2.length, 1);
      expect(ttl2[0].id, id); // They should be the same
      expect(ttl2[0].startDate, now.add(min5));
      expect(ttl2[0].lowTarget, 100);
      expect(ttl2[0].highTarget, 120);
      expect(ttl2[0].duration, 30); // Duration should be the only thing updated

      var tt3 = TempTarget(
        startDate: now.add(min5),
        duration: 30,
        lowTarget: 100,
        highTarget: 120,
        eid: "1",
      );
      expect(await SQLToTempTarget().upsertAll([tt3]), false);

      var tt4 = TempTarget(
        startDate: now.add(min5),
        duration: 30,
        lowTarget: 420,
        highTarget: 440,
        id: id,
        eid: "1",
      );

      expect(await SQLToTempTarget().upsertAll([tt4]), true);

      var ttl4 = await TempTarget.query();
      expect(ttl4.length, 1);
      expect(ttl4[0].id, id); // They should be the same
      expect(ttl4[0].startDate, now.add(min5));
      expect(ttl4[0].lowTarget, 420);
      expect(ttl4[0].highTarget, 440);
      expect(ttl4[0].duration, 30); // Duration should be the only thing updated
    });

    test('update duration to 0', () async {
      var tt1 = TempTarget(
        startDate: now.add(min5),
        duration: 60,
        lowTarget: 100,
        highTarget: 120,
        eid: "1",
      );
      expect(await SQLToTempTarget().upsertAll([tt1]), true);

      var ttl1 = await TempTarget.query();
      expect(ttl1.length, 1);
      expect(ttl1[0].startDate, now.add(min5));
      expect(ttl1[0].lowTarget, 100);
      expect(ttl1[0].highTarget, 120);
      expect(ttl1[0].duration, 60);

      var tt4 = TempTarget(
        startDate: now.add(min5),
        duration: 0,
        lowTarget: 100,
        highTarget: 120,
        eid: "1",
      );
      expect(await SQLToTempTarget().upsertAll([tt4]), true);

      var ttl2 = await TempTarget.query();
      expect(ttl2.length, 1);
      expect(ttl2[0].startDate, now.add(min5));
      expect(ttl2[0].lowTarget, 100);
      expect(ttl2[0].highTarget, 120);
      expect(ttl2[0].duration, 0);
    });
  });
}
