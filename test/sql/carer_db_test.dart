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
      await db.deleteAll();
      await db.close();
    });

    test('batchCreateOrUpdateSGVs', () async {
      // create SGVs
      var ret = await db.batchCreateOrUpdateSGVs([
        {'value': 1, 'date': 1},
        {'value': 2, 'date': 2},
      ]);
      expect(ret, 2);
      expect(await db.countSGVs(), 2);
      expect((await db.lastSGV())!['value'], 2);

      // fetch SGVs
      ret = await db.batchCreateOrUpdateSGVs([
        {'value': 1, 'date': 1},
        {'value': 2, 'date': 2},
      ]);
      expect(await db.countSGVs(), 2);
      expect(ret, 2);

      ret = await db.batchCreateOrUpdateSGVs([
        {'value': 2, 'date': 2},
        {'value': 1, 'date': 2}, // new at same date
      ]);
      expect(await db.countSGVs(), 3);
      // Should be ordered by date, then lowest value
      expect((await db.lastSGV())!['value'], 1);
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
  });
}
