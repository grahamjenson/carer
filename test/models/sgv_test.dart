import 'package:carer/mappers/sql_mappers.dart';
import 'package:carer/models/sgv.dart';
import 'package:carer/sql/carer_db.dart';
import 'package:carer/sql/sqlmodel.dart';
import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';

import '../sql/utils.dart';
import '../test_utils.dart';

void main() async {
  await sqfliteTestInit();

  group('SGV', () {
    DateTime now = DateTime(2020, 1, 1, 12);
    Duration min5 = const Duration(minutes: 5);
    Duration hour48 = const Duration(hours: 48);

    setUp(() async {});

    tearDown(() async {
      await (await CarerDB.instance).deleteAll();
    });

    test('lastMins', () async {
      expect(await SGV(value: 2, date: now.subtract(min5), eid: "1").save(), true);
      expect(await SGV(value: 1, date: now, eid: "2").save(), true);
      expect(await CleanSGV.count(), 2);

      await withClock(Clock.fixed(now), () async {
        var sgvs = await CleanSGV.lastMins(1);
        expect(sgvs.length, 1);
        sgvs = await CleanSGV.lastMins(10);
        expect(sgvs.length, 2);
      });
    });

    test("lastSGV", () async {
      var sgv = CleanSGV.lastSGV().value;
      expect(sgv, null);
      expect(await CleanSGV.count(), 0);

      expect(await SGV(value: 2, date: now.subtract(min5), eid: "1").save(), true);
      expect(await CleanSGV.count(), 1);
      sgv = CleanSGV.lastSGV().value;
      expect(sgv!.value, 2);
      expect(sgv.rate5m, null);

      // Add more recent number

      expect(await SGV(value: 1, date: now, eid: "2").save(), true);
      expect(await CleanSGV.count(), 2);
      sgv = CleanSGV.lastSGV().value;
      expect(sgv!.value, 1);
      expect(sgv.rate5m, -1);
    });

    test("percents", () async {
      expect(await SGV(value: 100, date: now.subtract(hour48), eid: "1").save(), true);
      expect(await SGV(value: 100, date: now.subtract(min5 + min5), eid: "2").save(), true);
      expect(await SGV(value: 100, date: now.subtract(min5), eid: "3").save(), true);

      await withClock(Clock.fixed(now), () async {
        var percent = await CleanSGV.todaysPercentage.future;
        expect(percent, 100.0);
      });
    });

    test('orderOFSVGs', () async {
      // create SGVs
      var ret = await Future.wait([
        SQLToSGV().aToB(SQLRow({'value': 1, 'timestamp': minTime(0), "eid": "1"})).save(),
        SQLToSGV().aToB(SQLRow({'value': 2, 'timestamp': minTime(5), "eid": "2"})).save(),
      ]);
      expect(ret.where((b) => b).length, 2);

      expect(await CleanSGV.count(), 2);
      var sgvs = await CleanSGV.query();
      expect(sgvs.length, 2);
      expect(sgvs.first.value, 2);

      // fetch SGVs
      ret = await Future.wait([
        SQLToSGV().aToB(SQLRow({'value': 1, 'timestamp': minTime(0), "eid": "1"})).save(),
        SQLToSGV().aToB(SQLRow({'value': 2, 'timestamp': minTime(5), "eid": "2"})).save(),
      ]);

      expect(ret.where((b) => b).length, 0); // Nothing was changed

      sgvs = await CleanSGV.query();
      expect(sgvs.length, 2);
      expect(sgvs.first.value, 2);

      ret = await Future.wait([
        SQLToSGV().aToB(SQLRow({'value': 2, 'timestamp': minTime(5), "eid": "2"})).save(),
        SQLToSGV().aToB(SQLRow({'value': 1, 'timestamp': minTime(5), "eid": "3"})).save(), // new at same date
      ]);

      expect(ret.where((b) => b).length, 1); // only one new value

      // Should be ordered by date, then lowest value
      sgvs = await CleanSGV.query();
      expect(sgvs.length, 3);
      expect(sgvs.first.value, 1);
    });

    test('validation', () async {
      List<Map<String, Object>> badInputs = [
        {},
        {'value': 1},
        {'timestamp': minTime(0)},
        {'value': 1, 'timestamp': '1'},
        {'value': '1', 'timestamp': minTime(0)},
        {'value': '1', 'timestamp': '1'},
      ];

      for (var badInput in badInputs) {
        try {
          SQLToSGV().aToB(SQLRow(badInput));
        } catch (e) {
          expect(e, isA<ArgumentError>());
        }
      }
    });

    test("countSGVs", () async {
      var ret = await Future.wait([
        SQLToSGV().aToB(SQLRow({'timestamp': minTime(0), 'value': 4, "eid": "1"})).save(),
        SQLToSGV().aToB(SQLRow({'timestamp': minTime(5), 'value': 3, "eid": "2"})).save(),
        SQLToSGV().aToB(SQLRow({'timestamp': minTime(10), 'value': 2, "eid": "3"})).save(),
        SQLToSGV().aToB(SQLRow({'timestamp': minTime(15), 'value': 1, "eid": "4"})).save(),
      ]);
      expect(ret.where((b) => b).length, 4);

      expect(await CleanSGV.count(), 4);
      expect(await CleanSGV.count(after: minTime(10)), 2); // inclusive
      expect(await CleanSGV.count(before: minTime(15)), 3); // exclusive
      expect(await CleanSGV.count(low: 2), 3); // inclusive
      expect(await CleanSGV.count(high: 4), 3); // exclusive

      expect(await CleanSGV.count(after: minTime(10), before: minTime(15), low: 2, high: 3), 1);
    });

    test("sgvs", () async {
      // create SGVs
      var ret = await Future.wait([
        SQLToSGV().aToB(SQLRow({'timestamp': minTime(0), 'value': 4, "eid": "1"})).save(),
        SQLToSGV().aToB(SQLRow({'timestamp': minTime(5), 'value': 3, "eid": "2"})).save(),
        SQLToSGV().aToB(SQLRow({'timestamp': minTime(10), 'value': 2, "eid": "3"})).save(),
        SQLToSGV().aToB(SQLRow({'timestamp': minTime(15), 'value': 1, "eid": "4"})).save(),
      ]);
      expect(ret.where((b) => b).length, 4);

      // fetch SGVs
      var sgvs = await CleanSGV.query(after: minTime(5)); // inclusive
      expect(sgvs.length, 3);
      expect(sgvs[0].value, 1);
      expect(sgvs[1].value, 2);
      expect(sgvs[2].value, 3);

      sgvs = await CleanSGV.query(before: minTime(10)); // exclusive
      expect(sgvs.length, 2);
      expect(sgvs[0].value, 3);
      expect(sgvs[1].value, 4);

      sgvs = await CleanSGV.query(low: 3); // inclusive
      expect(sgvs.length, 2);
      expect(sgvs[0].value, 3);
      expect(sgvs[1].value, 4);

      sgvs = await CleanSGV.query(high: 3); // exclusive
      expect(sgvs.length, 2);
      expect(sgvs[0].value, 1);
      expect(sgvs[1].value, 2);

      sgvs = await CleanSGV.query(limit: 1); // inclusive
      expect(sgvs.length, 1);
      expect(sgvs[0].value, 1);
    });

    group("clean sgvs", () {
      test("close sgvs", () async {
        var ret = await Future.wait([
          SQLToSGV().aToB(SQLRow({'timestamp': minTime(0), 'value': 4, "eid": "1"})).save(),
          SQLToSGV().aToB(SQLRow({'timestamp': minTime(5), 'value': 3, "eid": "2"})).save(),
          SQLToSGV().aToB(SQLRow({'timestamp': minTime(10), 'value': 5, "eid": "3"})).save(),
          SQLToSGV().aToB(SQLRow({'timestamp': minTime(15), 'value': 1, "eid": "4"})).save(),
          SQLToSGV().aToB(SQLRow({'timestamp': minTime(16), 'value': 2, "eid": "5"})).save(),
        ]);
        expect(ret.where((b) => b).length, 5);

        var sgvs = await CleanSGV.query();
        expect(sgvs.length, 5);
        expect(sgvs[0].value, 2);
        expect(sgvs[1].value, 1);
        expect(sgvs[2].value, 5);

        // Both top values should point to the same previous id
        expect(sgvs[0].idBefore, sgvs[2].id);
        expect(sgvs[1].idBefore, sgvs[2].id);

        // Both values diffs and rate5m should be the same
        expect(sgvs[0].diff, -3);
        expect(sgvs[1].diff, -4);
        expect(sgvs[0].rate5m, -3);
        expect(sgvs[1].rate5m, -4);
      });

      test("close sgvs", () async {
        var ret = await Future.wait([
          SQLToSGV().aToB(SQLRow({'timestamp': minTime(0), 'value': 1, "eid": "1"})).save(),
          SQLToSGV().aToB(SQLRow({'timestamp': minTime(15), 'value': 5, "eid": "2"})).save(),
          SQLToSGV().aToB(SQLRow({'timestamp': minTime(30), 'value': 20, "eid": "3"})).save(),
        ]);
        expect(ret.where((b) => b).length, 3);

        var sgvs = await CleanSGV.query();
        expect(sgvs.length, 3);
        expect(sgvs[0].value, 20);
        expect(sgvs[1].value, 5);
        expect(sgvs[2].value, 1);

        // Both values diffs and rate5m should be the same
        expect(sgvs[0].diff, 15);
        expect(sgvs[1].diff, 4);
        expect(sgvs[0].rate5m, 5);
        expect(sgvs[1].rate5m, 1);
      });
    });
  });
}
