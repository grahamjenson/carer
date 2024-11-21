import 'package:carer/mappers/sql/sgv.dart';
import 'package:carer/models/clean_sgv.dart';
import 'package:carer/models/sql/sgv.dart';
import 'package:carer/sql/sqlmodel.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_utils.dart';

void main() async {
  agroup("SGV", () {
    atest("percents", (DateTime now) async {
      var inRange = 120;
      var outOfRange = 10;

      var todaysSGVs = await createSVGs([(inRange, min20), (outOfRange, min10), (inRange, min5), (outOfRange, min0)]);
      expect(todaysSGVs, 4);
      expect(SGV.count(), 4);

      var yesterdaysSGVs = await createSVGs([(outOfRange, hour24 + min20), (inRange, hour24 + min10), (inRange, hour24 + min5), (inRange, hour24)]);

      expect(yesterdaysSGVs, 4);
      expect(SGV.count(), 8);

      var percent = SGV.todaysPercentage.value;
      expect(percent, 50.0);

      var ypercent = SGV.yesterdaysPercentage.value;

      expect(ypercent, 75.0);
    });
  });

  agroup('CleanSGV', () {
    atest("lastSGV", (DateTime now) async {
      await createSVGs([(2, min5)]);

      expect(CleanSGV.lastSGV.value, CleanSGV(2, now.subtract(min5)));
      expect(CleanSGV.count(), 1);

      await createSVGs([(1, min0)]);

      expect(CleanSGV.lastSGV.value, CleanSGV(1, now));
      expect(CleanSGV.count(), 2);
      return true;
    });

    atest('saveAll', () async {
      // create SGVs
      var ret = await createSVGsWithEIDs([("a", 1, min20), ("b", 2, min15)]);
      expect(ret, 2);

      expect(CleanSGV.count(), 2);

      var sgvs = CleanSGV.last2Days.value;
      expect(sgvs.length, 2);
      expect(sgvs.first.value, 2);

      // fetch SGVs
      ret = await createSVGsWithEIDs([("a", 1, min20), ("b", 2, min15)]);

      expect(ret, 0); // Nothing was changed

      sgvs = CleanSGV.last2Days.value;
      expect(sgvs.length, 2);
      expect(sgvs.first.value, 2);

      ret = await createSVGsWithEIDs([("b", 2, min15), ("c", 3, min10)]);

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
