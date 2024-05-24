// test the CarerDB that it inserts and upserts data

import 'package:carer/sql/carer_db.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Initialize sqflite for test.
void sqfliteTestInit() {
  // Initialize ffi implementation
  sqfliteFfiInit();
  // Set global factory
  databaseFactory = databaseFactoryFfi;
}

void main() {
  sqfliteTestInit();

  group('CarerDB', () {
    late CarerDB db;

    setUp(() async {
      db = await CarerDB.instance;
    });

    tearDown(() async {
      await db.recreate();
    });

    test('batchCreateOrUpdateSGVs', () async {
      // create SGVs
      var ret = await db.batchCreateOrUpdateSGVs([
        {'value': 1, 'date': 1},
        {'value': 2, 'date': 2},
      ]);
      expect(ret, 2);
      expect(await db.countSGVs(), 2);
      var sgvs = await db.sgvs();
      expect(sgvs.length, 2);
      expect(sgvs.first['value'], 2);

      // fetch SGVs
      ret = await db.batchCreateOrUpdateSGVs([
        {'value': 1, 'date': 1},
        {'value': 2, 'date': 2},
      ]);
      expect(await db.countSGVs(), 2);
      expect(ret, 2);
      sgvs = await db.sgvs();
      expect(sgvs.length, 2);
      expect(sgvs.first['value'], 2);

      ret = await db.batchCreateOrUpdateSGVs([
        {'value': 2, 'date': 2},
        {'value': 1, 'date': 2}, // new at same date
      ]);
      expect(await db.countSGVs(), 3);
      // Should be ordered by date, then lowest value
      sgvs = await db.sgvs();
      expect(sgvs.length, 3);
      expect(sgvs.first['value'], 1);
      expect(ret, 2);
    });

    test('batchCreateOrUpdateSGVs errors', () async {
      List<Map<String, Object>> badInputs = [
        {},
        {'value': 1},
        {'date': 1},
        {'value': 1, 'date': -1},
        {'value': -1, 'date': 1},
        {'value': 1, 'date': 1, 'extra': 1},
        {'value': 1, 'date': '1'},
        {'value': '1', 'date': 1},
        {'value': '1', 'date': '1'},
      ];

      for (var badInput in badInputs) {
        try {
          await db.batchCreateOrUpdateSGVs([badInput]);
          fail('Should have thrown for $badInput');
        } catch (e) {
          expect(e, isA<ArgumentError>());
        }
      }
    });

    test("countSGVs", () async {
      // create SGVs
      var ret = await db.batchCreateOrUpdateSGVs([
        {'date': 1, 'value': 4},
        {'date': 2, 'value': 3},
        {'date': 3, 'value': 2},
        {'date': 4, 'value': 1},
      ]);
      expect(ret, 4);
      expect(await db.countSGVs(), 4);
      expect(await db.countSGVs(after: 2), 3); // inclusive
      expect(await db.countSGVs(before: 4), 3); // exclusive
      expect(await db.countSGVs(low: 2), 3); // inclusive
      expect(await db.countSGVs(high: 4), 3); // exclusive

      expect(await db.countSGVs(after: 2, before: 4, low: 2, high: 3), 1);
    });

    test("sgvs", () async {
      // create SGVs
      var ret = await db.batchCreateOrUpdateSGVs([
        {'date': 1, 'value': 4},
        {'date': 2, 'value': 3},
        {'date': 3, 'value': 2},
        {'date': 4, 'value': 1},
      ]);
      expect(ret, 4);

      // fetch SGVs
      var sgvs = await db.sgvs(after: 2); // inclusive
      expect(sgvs.length, 3);
      expect(sgvs[0]['value'], 1);
      expect(sgvs[1]['value'], 2);
      expect(sgvs[2]['value'], 3);

      sgvs = await db.sgvs(before: 3); // inclusive
      expect(sgvs.length, 2);
      expect(sgvs[0]['value'], 3);
      expect(sgvs[1]['value'], 4);

      sgvs = await db.sgvs(low: 3); // inclusive
      expect(sgvs.length, 2);
      expect(sgvs[0]['value'], 3);
      expect(sgvs[1]['value'], 4);

      sgvs = await db.sgvs(high: 3); // inclusive
      expect(sgvs.length, 2);
      expect(sgvs[0]['value'], 1);
      expect(sgvs[1]['value'], 2);

      sgvs = await db.sgvs(limit: 1); // inclusive
      expect(sgvs.length, 1);
      expect(sgvs[0]['value'], 1);
    });
  });
}
