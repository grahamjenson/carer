import 'package:carer/mappers/sql/sgv.dart';
import 'package:carer/models/clean_sgv.dart';
import 'package:carer/models/sql/sgv.dart';
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

    test("lastSGV", () async {
      var sgv = CleanSGV.lastSGV.value;
      expect(sgv, null);
      expect(CleanSGV.count(), 0);

      expect(await SQLToSGV().save(SGV(value: 2, date: now.subtract(min5), eid: "1")), true);
      expect(CleanSGV.count(), 1);
      sgv = CleanSGV.lastSGV.value;
      expect(sgv!.value, 2);
      expect(sgv.rate5m, null);

      // Add more recent number

      expect(await SQLToSGV().save(SGV(value: 1, date: now, eid: "2")), true);
      expect(CleanSGV.count(), 2);
      sgv = CleanSGV.lastSGV.value;
      expect(sgv!.value, 1);
      expect(sgv.rate5m, -1);
    });

    test("percents", () async {
      expect(await SQLToSGV().save(SGV(value: 100, date: now.subtract(hour48), eid: "1")), true);
      expect(await SQLToSGV().save(SGV(value: 100, date: now.subtract(min5 + min5), eid: "2")), true);
      expect(await SQLToSGV().save(SGV(value: 100, date: now.subtract(min5), eid: "3")), true);

      await withClock(Clock.fixed(now), () async {
        var percent = CleanSGV.todaysPercentage.value;
        expect(percent, 100.0);
      });
    });

    test('orderOFSVGs', () async {
      // create SGVs
      var ret = await Future.wait([
        SQLToSGV().saveRow(SQLRow({'value': 1, 'timestamp': minTime(0), "eid": "1"})),
        SQLToSGV().saveRow(SQLRow({'value': 2, 'timestamp': minTime(5), "eid": "2"})),
      ]);
      expect(ret.where((b) => b).length, 2);

      expect(CleanSGV.count(), 2);
      var sgvs = CleanSGV.last2Days.value;
      expect(sgvs.length, 2);
      expect(sgvs.first.value, 2);

      // fetch SGVs
      ret = await Future.wait([
        SQLToSGV().saveRow(SQLRow({'value': 1, 'timestamp': minTime(0), "eid": "1"})),
        SQLToSGV().saveRow(SQLRow({'value': 2, 'timestamp': minTime(5), "eid": "2"})),
      ]);

      expect(ret.where((b) => b).length, 0); // Nothing was changed

      sgvs = CleanSGV.last2Days.value;
      expect(sgvs.length, 2);
      expect(sgvs.first.value, 2);

      ret = await Future.wait([
        SQLToSGV().saveRow(SQLRow({'value': 2, 'timestamp': minTime(5), "eid": "2"})),
        SQLToSGV().saveRow(SQLRow({'value': 1, 'timestamp': minTime(5), "eid": "3"})), // new at same date
      ]);

      expect(ret.where((b) => b).length, 1); // only one new value

      // Should be ordered by date, then lowest value
      sgvs = CleanSGV.last2Days.value;
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
  });
}
