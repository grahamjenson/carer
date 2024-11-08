import 'package:carer/mappers/sql/logs/alarms_log.dart';
import 'package:carer/models/details/alarms/alarms.dart';
import 'package:carer/models/sql/logs/alarm_logs.dart';
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
      var now = clock.now();
      var startTime = DateTime(now.year, now.month, now.day, now.hour, now.minute);
      var al = AlarmLog(
        type: AlarmType.low,
        stage: AlarmStage.pending,
        conditions: {},
        startDate: startTime,
      );
      expect(await SQLToAlarmLogs().save(al), true);

      await SQLToAlarmLogs().last2Days().then((value) {
        expect(value.length, 1);
        expect(value[0].type, AlarmType.low);
        expect(value[0].stage, AlarmStage.pending);
        expect(value[0].conditions, {});
        expect(value[0].startDate, startTime);
      });

      var log = await SQLToAlarmLogs().findUnfinishedAlarmOfTypeAndStage(AlarmType.low, AlarmStage.pending);
      expect(log, isNotNull);
      expect(log!.startDate, startTime);

      log.endDate = clock.now();
      expect(await SQLToAlarmLogs().save(log), true);

      log = await SQLToAlarmLogs().findUnfinishedAlarmOfTypeAndStage(AlarmType.low, AlarmStage.pending);
      expect(log, isNull);
    });
  });
}
