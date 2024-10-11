import 'package:carer/mappers/sql/alarms_log.dart';
import 'package:carer/models/sql/alarm_logs.dart';
import 'package:carer/services/alarms/alarms.dart';
import 'package:carer/sql/carer_db.dart';
import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_utils.dart';

void main() async {
  await sqfliteTestInit();

  group('AlarmLog', () {
    setUp(() async {
      await (await CarerDB.instance).deleteAll();
    });

    tearDown(() async {});

    test("create", () async {
      var al = AlarmLog(
        eid: "EID",
        type: AlarmType.low,
        stage: AlarmStage.pending,
        conditions: {},
        startDate: clock.now(),
      );
      expect(await SQLToAlarmLogs().save(al), true);

      SQLToAlarmLogs().last2Days().then((value) {
        expect(value.length, 1);
        expect(value[0].eid, "EID");
        expect(value[0].type, AlarmType.low);
        expect(value[0].stage, AlarmStage.pending);
        expect(value[0].conditions, {});
      });
    });
  });
}
