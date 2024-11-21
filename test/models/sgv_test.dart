import 'package:carer/mappers/sql/sgv.dart';
import 'package:carer/models/clean_sgv.dart';
import 'package:carer/models/sql/sgv.dart';
import 'package:carer/sql/sqlmodel.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_utils.dart';

void main() async {
  agroup('CleanSGV', () {
    atest("lastSGV", (DateTime now) async {
      await createSVGs([("a", 2, 5)]);

      expect(CleanSGV.lastSGV.value, CleanSGV(2, now.subtract(min5)));
      expect(CleanSGV.count(), 1);

      await createSVGs([("b", 1, 0)]);

      expect(CleanSGV.lastSGV.value, CleanSGV(1, now));
      expect(CleanSGV.count(), 2);
      return true;
    });

    atest("percents", (DateTime now) async {
      expect(await SQLToSGV().save(SGV(value: 100, date: now.subtract(hour48), eid: "1")), true);
      expect(await SQLToSGV().save(SGV(value: 100, date: now.subtract(min5 + min5), eid: "2")), true);
      expect(await SQLToSGV().save(SGV(value: 100, date: now.subtract(min5), eid: "3")), true);

      var percent = CleanSGV.todaysPercentage.value;
      expect(percent, 100.0);
    });

    atest('saveAll', () async {
      // create SGVs
      var ret = await createSVGs([("a", 1, 20), ("b", 2, 15)]);
      expect(ret, 2);

      expect(CleanSGV.count(), 2);

      var sgvs = CleanSGV.last2Days.value;
      expect(sgvs.length, 2);
      expect(sgvs.first.value, 2);

      // fetch SGVs
      ret = await createSVGs([("a", 1, 20), ("b", 2, 15)]);

      expect(ret, 0); // Nothing was changed

      sgvs = CleanSGV.last2Days.value;
      expect(sgvs.length, 2);
      expect(sgvs.first.value, 2);

      ret = await createSVGs([("b", 2, 15), ("c", 3, 10)]);

      expect(ret, 1); // only one new value

      // Should be ordered by date, then lowest value
      sgvs = CleanSGV.last2Days.value;

      expect(sgvs.length, 3);
      expect(sgvs.first.value, 3);
    });

    atest('validation', () async {
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
