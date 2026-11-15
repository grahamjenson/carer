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

      var todaysSGVs = await createSGVsInOrder([inRange, outOfRange, inRange, outOfRange]);
      expect(todaysSGVs, 4);
      expect(SGV.count(), 4);

      var yesterdaysSGVs = await createSGVsInOrder([outOfRange, inRange, inRange, inRange], now: now.subtract(hour24));

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

    atest("rate5m", () async {
      // Checking that the rate
      var ret = await createSVGs([(100, min15), (120, min5)]);
      expect(ret, 2);
      expect(CleanSGV.count(), 2);

      expect(CleanSGV.lastSGV.value!.rate5m, 10);

      ret = await createSVGs([(140, min0)]);
      expect(ret, 1);
      expect(CleanSGV.count(), 3);
      var last = CleanSGV.lastSGV.value!;

      expect(last.rate5m, 20);
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

  agroup("CleanSGV.cleanAgoReadings", () {
    atest("works", () async {
      await createSVGs([(80, min15), (90, min10), (100, min5), (110, min0)]);
      var list = CleanSGV.cleanAgoReadings(min15);
      expect(list.length, 4);
      var values = list.map((e) => e.value);
      var ages = list.map((e) => e.age);
      expect(values, [110, 100, 90, 80]);
      expect(ages, [min0, min5, min10, min15]);
    });

    atest("doesnt select items too close", () async {
      await createSVGs([(80, min15), (90, min10), (100, min5), (105, min1), (110, min0)]);
      var list = CleanSGV.cleanAgoReadings(min15);
      expect(list.length, 4);
      var values = list.map((e) => e.value);
      var ages = list.map((e) => e.age);

      expect(values, [110, 100, 90, 80]);
      expect(ages, [min0, min5, min10, min15]);
    });

    atest("doesnt select items too close (elimination)", () async {
      await createSVGs([(80, min15), (90, min10), (100, min5), (105, min3), (110, min0)]);
      var list = CleanSGV.cleanAgoReadings(min15);
      expect(list.length, 4);
      var values = list.map((e) => e.value);
      var ages = list.map((e) => e.age);

      expect(values, [110, 105, 90, 80]);
      expect(ages, [min0, min3, min10, min15]);
    });

    atest("selects all values that are available value", () async {
      await createSVGs([(80, min15), (90, min12), (95, min9), (100, min6), (105, min3), (110, min0)]);
      var list = CleanSGV.cleanAgoReadings(min15);
      expect(list.length, 6);
      var values = list.map((e) => e.value);
      var ages = list.map((e) => e.age);

      expect(values, [110, 105, 100, 95, 90, 80]);
      expect(ages, [min0, min3, min6, min9, min12, min15]);
    });
  });

  agroup("CleanSGV.triggerWindowAge", () {
    atest("works", () async {
      var age = CleanSGV.triggerWindowAge(min0, 10);
      expect(age, min10 + LAG_WIGGLE_DURATION);

      age = CleanSGV.triggerWindowAge(min3, 10);
      expect(age, min10 + min3 + LAG_WIGGLE_DURATION);
    });
  });
  agroup("CleanSGV.sgvsInTriggerWindow", () {
    atest("works", () async {
      await createSVGs([(80, min15), (90, min10), (100, min5), (110, min0)]);
      var list = CleanSGV.sgvsInTriggerWindow(10);
      expect(list.length, 3);
      var values = list.map((e) => e.value);
      var ages = list.map((e) => e.age);
      expect(values, [110, 100, 90]);
      expect(ages, [min0, min5, min10]);
    });

    atest("works with window moving", () async {
      await createSVGs([(80, min19), (90, min14), (100, min9), (110, min4)]);
      var list = CleanSGV.sgvsInTriggerWindow(10);
      expect(list.length, 3);
      var values = list.map((e) => e.value);
      var ages = list.map((e) => e.age);
      expect(values, [110, 100, 90]);
      expect(ages, [min4, min9, min14]);
    });

    atest("works at edge window with Lag", () async {
      await createSVGs([(80, min20 + sec20), (90, min15 + sec20), (100, min10 + sec20), (110, min5 + sec20)]);
      var list = CleanSGV.sgvsInTriggerWindow(10);
      expect(list.length, 3);
      var values = list.map((e) => e.value);
      var ages = list.map((e) => e.age);
      expect(values, [110, 100, 90]);
      expect(ages, [min5 + sec20, min10 + sec20, min15 + sec20]);
    });

    atest("doest accept past lag", () async {
      await createSVGs([(80, min21), (90, min16), (100, min11), (110, min6)]);
      var list = CleanSGV.sgvsInTriggerWindow(10);
      expect(list.length, 2);
      var values = list.map((e) => e.value);
      var ages = list.map((e) => e.age);
      expect(values, [110, 100]);
      expect(ages, [min6, min11]);
    });
  });
}
