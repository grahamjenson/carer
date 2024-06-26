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

    test("create and update", () async {
      var tt1 = TempTarget(
        startDate: now.add(min5),
        duration: 60,
        lowTarget: 100,
        highTarget: 120,
      );
      expect(await tt1.upsert(), true);

      var ttl1 = await TempTarget.query();
      expect(ttl1.length, 1);
      expect(ttl1[0].startDate, now.add(min5));
      expect(ttl1[0].lowTarget, 100);
      expect(ttl1[0].highTarget, 120);
      expect(ttl1[0].duration, 60);

      var tt2 = TempTarget(
        startDate: now.add(min5),
        duration: 30,
        lowTarget: 100,
        highTarget: 120,
      );
      expect(await tt2.upsert(), true);

      var ttl2 = await TempTarget.query();
      expect(ttl2.length, 1);
      expect(ttl2[0].id, ttl1[0].id); // They should be the same
      expect(ttl2[0].startDate, now.add(min5));
      expect(ttl2[0].lowTarget, 100);
      expect(ttl2[0].highTarget, 120);
      expect(ttl2[0].duration, 30); // Duration should be the only thing updated

      var tt3 = TempTarget(
        startDate: now.add(min5),
        duration: 30,
        lowTarget: 100,
        highTarget: 120,
      );
      expect(await tt3.upsert(), false);
    });

    test(" fix bad data", () async {
      var tt1 = TempTarget(
        startDate: now,
        duration: 120,
        lowTarget: 10,
        highTarget: 100,
      );
      expect(await tt1.upsert(), true);

      var tt2 = TempTarget(
        startDate: now.add(min1),
        duration: 120,
        lowTarget: 20,
        highTarget: 200,
      );
      expect(await tt2.upsert(), true);

      var all = await TempTarget.query();

      expect(all.length, 2);
      expect(all[0].lowTarget, 20);
      expect(all[1].lowTarget, 10);

      expect(all[0].duration, 120);
      expect(all[1].duration, 120); // This is the error that needs fixing

      // Fix the temp targets
      var ret = await TempTarget.fixData();
      expect(ret, 1);
      all = await TempTarget.query();

      expect(all.length, 2);
      expect(all[0].lowTarget, 20);
      expect(all[1].lowTarget, 10);

      expect(all[0].duration, 120);
      expect(all[1].duration, 60);

      ret = await TempTarget.fixData();
      expect(ret, 0);
    });

    test(" fix multiple bad datas", () async {
      var a = TempTarget(
        startDate: now,
        duration: 3000,
        lowTarget: 10,
        highTarget: 100,
      );
      expect(await a.upsert(), true);

      var b1 = TempTarget(
        startDate: now.add(min1),
        duration: 20,
        lowTarget: 20,
        highTarget: 200,
      );
      expect(await b1.upsert(), true);

      var b2 = TempTarget(
        startDate: now.add(min1).add(min1),
        duration: 30,
        lowTarget: 30,
        highTarget: 300,
      );
      expect(await b2.upsert(), true);

      var all = await TempTarget.query();

      expect(all.length, 3);
      expect(all[0].lowTarget, 30);
      expect(all[1].lowTarget, 20);
      expect(all[2].lowTarget, 10);

      expect(all[0].duration, 30);
      expect(all[1].duration, 20); // This is the error that needs fixing
      expect(all[2].duration, 3000); // This is the error that needs fixing

      // Fix the temp targets
      var ret = await TempTarget.fixData();
      expect(ret, 1);
      all = await TempTarget.query();

      expect(all.length, 3);
      expect(all[0].lowTarget, 30);
      expect(all[1].lowTarget, 20);
      expect(all[2].lowTarget, 10);

      expect(all[0].duration, 30);
      expect(all[1].duration, 20);
      expect(all[2].duration, 60);

      ret = await TempTarget.fixData();
      expect(ret, 0);
    });

    test('update duration to 0', () async {
      var tt1 = TempTarget(
        startDate: now.add(min5),
        duration: 60,
        lowTarget: 100,
        highTarget: 120,
      );
      expect(await tt1.upsert(), true);

      var ttl1 = await TempTarget.query();
      expect(ttl1.length, 1);
      expect(ttl1[0].startDate, now.add(min5));
      expect(ttl1[0].lowTarget, 100);
      expect(ttl1[0].highTarget, 120);
      expect(ttl1[0].duration, 60);

      var tt2 = TempTarget(
        startDate: now.add(min5),
        duration: 0,
        lowTarget: 100,
        highTarget: 120,
      );
      expect(await tt2.upsert(), true);

      var ttl2 = await TempTarget.query();
      expect(ttl2.length, 1);
      expect(ttl2[0].startDate, now.add(min5));
      expect(ttl2[0].lowTarget, 100);
      expect(ttl2[0].highTarget, 120);
      expect(ttl2[0].duration, 0);
    });
  });
}
