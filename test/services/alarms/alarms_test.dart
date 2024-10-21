import 'package:carer/mappers/sql/bolus.dart';
import 'package:carer/mappers/sql/carbs.dart';
import 'package:carer/mappers/sql/profile.dart';
import 'package:carer/mappers/sql/sgv.dart';
import 'package:carer/mappers/sql/tempbasal.dart';
import 'package:carer/mappers/sql/temptarget.dart';
import 'package:carer/models/details/alarms/alarms.dart';
import 'package:carer/models/sql/sgv.dart';
import 'package:carer/services/settings/alarm_settings.dart';
import 'package:carer/services/settings/target_settings.dart';
import 'package:carer/sql/carer_db.dart';
import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test_utils.dart';

cleanSignals() {
  SQLToBolus().writeSignal.value = 0;
  SQLToCarbs().writeSignal.value = 0;
  SQLToProfile().writeSignal.value = 0;
  SQLToSGV().writeSignal.value = 0;
  SQLToTempBasal().writeSignal.value = 0;
  SQLToTempTarget().writeSignal.value = 0;
}

void main() async {
  await sqfliteTestInit();

  group("Alarms", () {
    setUp(() async {
      cleanSignals();
    });

    tearDown(() async {
      await (await CarerDB.instance).deleteAll();
      cleanSignals();
    });

    test("HighAlarm", () async {
      AlarmType alarm = AlarmType.high;
      var (trigger, active, smartSnooze) = alarm.alarmStatus();
      expect(trigger, false);
      expect(active, false);
      expect(smartSnooze, false);

      AlarmSettings().highAlarm = true;
      AlarmSettings().highMinutes = 10;
      TargetSettings().highTarget = 180;

      expect(
          await SQLToSGV().saveAll([
            SGV(value: 185, date: clock.now(), eid: "1"),
            SGV(value: 200, date: clock.minutesAgo(5), eid: "2"),
            SGV(value: 220, date: clock.minutesAgo(10), eid: "3"),
          ]),
          3);

      (trigger, active, smartSnooze) = alarm.alarmStatus();
      expect(trigger, true);
      expect(active, true);
      expect(smartSnooze, true);

      alarm.shortSummary();
    });

    test("LowAlarm", () async {
      AlarmType alarm = AlarmType.low;
      var (trigger, active, smartSnooze) = alarm.alarmStatus();
      expect(trigger, false);
      expect(active, false);
      expect(smartSnooze, false);

      AlarmSettings().lowAlarm = true;

      TargetSettings().lowTarget = 72;

      expect(await SQLToSGV().save(SGV(value: 70, date: clock.now(), eid: "1")), true);
      expect(await SQLToSGV().save(SGV(value: 60, date: clock.minutesAgo(5), eid: "2")), true);
      expect(await SQLToSGV().save(SGV(value: 50, date: clock.minutesAgo(10), eid: "3")), true);

      (trigger, active, smartSnooze) = alarm.alarmStatus();
      expect(trigger, true);
      expect(active, true);
      expect(smartSnooze, true);
      alarm.shortSummary();
    });

    test("UrgentHighAlarm", () async {
      AlarmType alarm = AlarmType.urgentHigh;
      var (trigger, active, smartSnooze) = alarm.alarmStatus();
      expect(trigger, false);
      expect(active, false);
      expect(smartSnooze, false);

      AlarmSettings().urgentHighAlarm = true;
      TargetSettings().highUrgent = 180;

      expect(await SQLToSGV().save(SGV(value: 185, date: clock.now(), eid: "1")), true);
      expect(await SQLToSGV().save(SGV(value: 200, date: clock.minutesAgo(5), eid: "2")), true);
      expect(await SQLToSGV().save(SGV(value: 220, date: clock.minutesAgo(10), eid: "3")), true);

      (trigger, active, smartSnooze) = alarm.alarmStatus();
      expect(trigger, true);
      expect(active, true);
      expect(smartSnooze, false);
      alarm.shortSummary();
    });

    test("UrgentLowAlarm", () async {
      AlarmType alarm = AlarmType.urgentLow;
      var (trigger, active, smartSnooze) = alarm.alarmStatus();
      expect(trigger, false);
      expect(active, false);
      expect(smartSnooze, false);

      AlarmSettings().urgentLowAlarm = true;
      TargetSettings().lowUrgent = 72;

      expect(await SQLToSGV().save(SGV(value: 70, date: clock.now(), eid: "1")), true);
      expect(await SQLToSGV().save(SGV(value: 60, date: clock.minutesAgo(5), eid: "2")), true);
      expect(await SQLToSGV().save(SGV(value: 50, date: clock.minutesAgo(10), eid: "3")), true);

      (trigger, active, smartSnooze) = alarm.alarmStatus();
      expect(trigger, true);
      expect(active, true);
      expect(smartSnooze, false);
      alarm.shortSummary();
    });

    test("FastRiseAlarm", () async {
      AlarmType alarm = AlarmType.fastRise;
      var (trigger, active, smartSnooze) = alarm.alarmStatus();
      expect(trigger, false);
      expect(active, false);
      expect(smartSnooze, false);

      AlarmSettings().fastRiseAlarmMinutes = 10;
      TargetSettings().fastRiseDelta = 10;

      expect(await SQLToSGV().save(SGV(value: 192, date: clock.now(), eid: "1")), true);
      expect(await SQLToSGV().save(SGV(value: 181, date: clock.minutesAgo(5), eid: "2")), true);
      expect(await SQLToSGV().save(SGV(value: 170, date: clock.minutesAgo(10), eid: "3")), true);

      (trigger, active, smartSnooze) = alarm.alarmStatus();
      expect(trigger, true);
      expect(active, true);
      expect(smartSnooze, false);
      alarm.shortSummary();
    });

    test("FastDropAlarm", () async {
      AlarmType alarm = AlarmType.fastDrop;
      var (trigger, active, smartSnooze) = alarm.alarmStatus();
      expect(trigger, false);
      expect(active, false);
      expect(smartSnooze, false);

      AlarmSettings().fastDropAlarmMinutes = 10;
      TargetSettings().fastDropDelta = -10;

      expect(await SQLToSGV().save(SGV(value: 110, date: clock.now(), eid: "1")), true);
      expect(await SQLToSGV().save(SGV(value: 130, date: clock.minutesAgo(5), eid: "2")), true);
      expect(await SQLToSGV().save(SGV(value: 150, date: clock.minutesAgo(10), eid: "3")), true);

      (trigger, active, smartSnooze) = alarm.alarmStatus();
      expect(trigger, true);
      expect(active, true);
      expect(smartSnooze, false);
      alarm.shortSummary();
    });

    test("NoDataAlarm", () async {
      AlarmType alarm = AlarmType.noData;
      var (trigger, active, smartSnooze) = alarm.alarmStatus();
      expect(trigger, false);
      expect(active, false);
      expect(smartSnooze, false);

      AlarmSettings().noDataAlarmMinutes = 20;

      expect(await SQLToSGV().save(SGV(value: 187, date: clock.minutesAgo(30), eid: "1")), true);
      expect(await SQLToSGV().save(SGV(value: 200, date: clock.minutesAgo(35), eid: "2")), true);
      expect(await SQLToSGV().save(SGV(value: 220, date: clock.minutesAgo(40), eid: "3")), true);

      (trigger, active, smartSnooze) = alarm.alarmStatus();
      expect(trigger, true);
      expect(active, true);
      expect(smartSnooze, false);
      alarm.shortSummary();
    });

    test("PredictiveLowAlarm", () async {
      AlarmType alarm = AlarmType.low;
      var (trigger, active, smartSnooze) = alarm.alarmStatus();
      expect(trigger, false);
      expect(active, false);
      expect(smartSnooze, false);

      AlarmSettings().lowPredictionAlarm = true;

      TargetSettings().lowTarget = 72;

      expect(await SQLToSGV().save(SGV(value: 80, date: clock.now(), eid: "1")), true);
      expect(await SQLToSGV().save(SGV(value: 100, date: clock.minutesAgo(5), eid: "2")), true);
      expect(await SQLToSGV().save(SGV(value: 120, date: clock.minutesAgo(10), eid: "3")), true);

      (trigger, active, smartSnooze) = alarm.alarmStatus();
      expect(trigger, true);
      expect(active, true);
      expect(smartSnooze, false);
      alarm.shortSummary();
    });
  });
}
