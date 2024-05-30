// test the CarerDB that it inserts and upserts data

import 'package:carer/sql/carer_db.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_utils.dart';
import 'utils.dart';

void main() {
  sqfliteTestInit();

  group('boluses', () {
    late CarerDB db;

    setUp(() async {
      db = await CarerDB.instance;
      await db.deleteAll();
    });

    tearDown(() async {});

    test("create", () async {
      var ret = await db.batchCreateOrUpdateBoluses([
        {'start': minTime(0), 'duration': 120, 'value': 0.5},
        {'start': minTime(5), 'duration': 180, 'value': 0.6},
      ]);
      expect(ret, 2);

      var t1 = await db.tempBasalAtTime(minTime(1));
      expect(t1, isNotNull);
      expect(t1!["value"], 0.5);
      expect(t1["start"], minTime(0));
      expect(t1["end"], minTime(0) + minTime(2));

      var t2 = await db.tempBasalAtTime(minTime(6));
      expect(t2, isNotNull);
      expect(t2!["value"], 0.6);
      expect(t2["start"], minTime(5));
      expect(t2["end"], minTime(5) + minTime(3));
    });

    test("upsert", () async {
      // updates the duration
      var ret = await db.batchCreateOrUpdateTempBasals([
        {'start': minTime(0), 'duration': 120, 'value': 0.5},
      ]);
      expect(ret, 1);

      var t1 = await db.tempBasalAtTime(minTime(1));
      expect(t1!["duration"], 120);
      var initID = t1["id"];

      ret = await db.batchCreateOrUpdateTempBasals([
        {'start': minTime(0), 'duration': 240, 'value': 0.5},
      ]);
      expect(ret, 1);

      var t2 = await db.tempBasalAtTime(minTime(1));
      expect(t2!["duration"], 240);
      expect(t2["id"], initID);

      // Creates new temp basal if value changes
      ret = await db.batchCreateOrUpdateTempBasals([
        {'start': minTime(0), 'duration': 240, 'value': 0.6},
      ]);
      expect(ret, 1);

      var t3 = await db.tempBasalAtTime(minTime(1));
      expect(t3!["value"], 0.6);
      expect(t3["id"], isNot(initID));
    });
  });
}
