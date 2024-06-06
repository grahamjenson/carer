import 'package:carer/models/temptarget.dart';
import 'package:carer/sql/carer_db.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_utils.dart';

void main() {
  sqfliteTestInit();

  group('Temptargets', () {
    DateTime now = DateTime(2020, 1, 1, 12);
    Duration min5 = const Duration(minutes: 5);
    Duration hour48 = const Duration(hours: 48);

    setUp(() async {});

    tearDown(() async {
      await (await CarerDB.instance).deleteAll();
    });

    test("create", () async {
      var tt = TempTarget(
        startDate: now.add(min5),
        duration: 60,
        targetLow: 100,
        targetHigh: 120,
      );
      expect(await tt.save(), true);

      var tt1 = await TempTarget.query();
      expect(tt1.length, 1);
      expect(tt1[0].startDate, now.add(min5));
      expect(tt1[0].targetLow, 100);
      expect(tt1[0].targetHigh, 120);
      expect(tt1[0].duration, 60);
    });
  });
}
