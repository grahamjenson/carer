import 'package:carer/mappers/sql/sgv.dart';
import 'package:carer/models/clean_sgv.dart';
import 'package:carer/models/sql/sgv.dart';
import 'package:carer/sql/sqlmodel.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_utils.dart';

void main() async {
  agroup('SGV', () {
    atest("lastSGV", (DateTime now) async {
      var stream = CleanSGV.lastSGV.stream;
      expect(stream, emits((o) {
        expect(o, null);
        expect(CleanSGV.count(), 0);
        return true;
      }));

      expect(await SQLToSGV().save(SGV(value: 2, date: now.subtract(min5), eid: "1")), true);
      expect(stream, emits((o) {
        expect(o, CleanSGV(2, now.subtract(min5)));
        expect(CleanSGV.count(), 1);
        return true;
      }));

      expect(await SQLToSGV().save(SGV(value: 1, date: now, eid: "2")), true);

      expect(stream, emits((o) {
        expect(o, CleanSGV(1, now));
        expect(CleanSGV.count(), 2);
        return true;
      }));
    });

    atest("percents", (DateTime now) async {
      expect(await SQLToSGV().save(SGV(value: 100, date: now.subtract(hour48), eid: "1")), true);
      expect(await SQLToSGV().save(SGV(value: 100, date: now.subtract(min5 + min5), eid: "2")), true);
      expect(await SQLToSGV().save(SGV(value: 100, date: now.subtract(min5), eid: "3")), true);

      var percent = CleanSGV.todaysPercentage.value;
      expect(percent, 100.0);
    });

    atest('orderOFSVGs', () async {
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
