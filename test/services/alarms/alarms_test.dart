import 'package:carer/models/model.dart';
import 'package:carer/models/sgv.dart';
import 'package:carer/services/alarms/alarms.dart';
import 'package:carer/services/prediction_service.dart';
import 'package:carer/services/settings/alarm_settings.dart';
import 'package:carer/services/settings/target_settings.dart';
import 'package:carer/sql/carer_db.dart';
import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test_utils.dart';

void main() async {
  await sqfliteTestInit();

  group("Alarms", () {
    setUp(() async {
      Model.cleanSignals();
      await SGV.lastSGV.future;
      await SGV.last3Hours.future;
    });

    tearDown(() async {
      await (await CarerDB.instance).deleteAll();
      Model.cleanSignals();
      await SGV.lastSGV.future;
      await SGV.last3Hours.future;
      PredictionService().predictionsSignal.recompute();
    });

    test("HighAlarm", () async {
      Alarm alarm = const HighAlarm();
      var (trigger, active, smartSnooze) = alarm.alarmStatus();
      expect(trigger, false);
      expect(active, false);
      expect(smartSnooze, false);

      AlarmSettings().highAlarm = true;
      AlarmSettings().highMinutes = 10;
      TargetSettings().highTarget = 180;

      expect(
          await SGV.saveAll([
            SGV(value: 185, date: clock.now(), eid: "1"),
            SGV(value: 200, date: clock.minutesAgo(5), eid: "2"),
            SGV(value: 220, date: clock.minutesAgo(10), eid: "3"),
          ]),
          3);

      await SGV.lastSGV.future;
      await SGV.last3Hours.future;

      (trigger, active, smartSnooze) = alarm.alarmStatus();
      expect(trigger, true);
      expect(active, true);
      expect(smartSnooze, true);

      alarm.status();
    });

    test("LowAlarm", () async {
      Alarm alarm = const LowAlarm();
      var (trigger, active, smartSnooze) = alarm.alarmStatus();
      expect(trigger, false);
      expect(active, false);
      expect(smartSnooze, false);

      AlarmSettings().lowAlarm = true;
      AlarmSettings().lowMinutes = 10;
      TargetSettings().lowTarget = 72;

      expect(await SGV(value: 70, date: clock.now(), eid: "1").save(), true);
      expect(await SGV(value: 60, date: clock.minutesAgo(5), eid: "2").save(), true);
      expect(await SGV(value: 50, date: clock.minutesAgo(10), eid: "3").save(), true);

      await SGV.lastSGV.future;
      await SGV.last3Hours.future;

      (trigger, active, smartSnooze) = alarm.alarmStatus();
      expect(trigger, true);
      expect(active, true);
      expect(smartSnooze, true);
      alarm.status();
    });

    test("UrgentHighAlarm", () async {
      Alarm alarm = const UrgentHighAlarm();
      var (trigger, active, smartSnooze) = alarm.alarmStatus();
      expect(trigger, false);
      expect(active, false);
      expect(smartSnooze, false);

      AlarmSettings().urgentHighAlarm = true;
      TargetSettings().highUrgent = 180;

      expect(await SGV(value: 185, date: clock.now(), eid: "1").save(), true);
      expect(await SGV(value: 200, date: clock.minutesAgo(5), eid: "2").save(), true);
      expect(await SGV(value: 220, date: clock.minutesAgo(10), eid: "3").save(), true);

      await SGV.lastSGV.future;
      await SGV.last3Hours.future;

      (trigger, active, smartSnooze) = alarm.alarmStatus();
      expect(trigger, true);
      expect(active, true);
      expect(smartSnooze, false);
      alarm.status();
    });

    test("UrgentLowAlarm", () async {
      Alarm alarm = const UrgentLowAlarm();
      var (trigger, active, smartSnooze) = alarm.alarmStatus();
      expect(trigger, false);
      expect(active, false);
      expect(smartSnooze, false);

      AlarmSettings().urgentLowAlarm = true;
      TargetSettings().lowUrgent = 72;

      expect(await SGV(value: 70, date: clock.now(), eid: "1").save(), true);
      expect(await SGV(value: 60, date: clock.minutesAgo(5), eid: "2").save(), true);
      expect(await SGV(value: 50, date: clock.minutesAgo(10), eid: "3").save(), true);

      await SGV.lastSGV.future;
      await SGV.last3Hours.future;

      (trigger, active, smartSnooze) = alarm.alarmStatus();
      expect(trigger, true);
      expect(active, true);
      expect(smartSnooze, false);
      alarm.status();
    });

    test("FastRiseAlarm", () async {
      Alarm alarm = const FastRiseAlarm();
      var (trigger, active, smartSnooze) = alarm.alarmStatus();
      expect(trigger, false);
      expect(active, false);
      expect(smartSnooze, false);

      AlarmSettings().fastRiseAlarm = true;
      AlarmSettings().fastRiseAlarmMinutes = 10;
      TargetSettings().fastRiseDelta = 10;

      expect(await SGV(value: 192, date: clock.now(), eid: "1").save(), true);
      expect(await SGV(value: 181, date: clock.minutesAgo(5), eid: "2").save(), true);
      expect(await SGV(value: 170, date: clock.minutesAgo(10), eid: "3").save(), true);

      await SGV.lastSGV.future;
      await SGV.last3Hours.future;

      (trigger, active, smartSnooze) = alarm.alarmStatus();
      expect(trigger, true);
      expect(active, true);
      expect(smartSnooze, false);
      alarm.status();
    });

    test("FastDropAlarm", () async {
      Alarm alarm = const FastDropAlarm();
      var (trigger, active, smartSnooze) = alarm.alarmStatus();
      expect(trigger, false);
      expect(active, false);
      expect(smartSnooze, false);

      AlarmSettings().fastDropAlarm = true;
      AlarmSettings().fastDropAlarmMinutes = 10;
      TargetSettings().fastDropDelta = -10;

      expect(await SGV(value: 110, date: clock.now(), eid: "1").save(), true);
      expect(await SGV(value: 130, date: clock.minutesAgo(5), eid: "2").save(), true);
      expect(await SGV(value: 150, date: clock.minutesAgo(10), eid: "3").save(), true);

      await SGV.lastSGV.future;
      await SGV.last3Hours.future;

      (trigger, active, smartSnooze) = alarm.alarmStatus();
      expect(trigger, true);
      expect(active, true);
      expect(smartSnooze, false);
      alarm.status();
    });

    test("NoDataAlarm", () async {
      Alarm alarm = const NoDataAlarm();
      var (trigger, active, smartSnooze) = alarm.alarmStatus();
      expect(trigger, false);
      expect(active, false);
      expect(smartSnooze, false);

      AlarmSettings().noDataAlarmMinutes = 20;

      expect(await SGV(value: 187, date: clock.minutesAgo(30), eid: "1").save(), true);
      expect(await SGV(value: 200, date: clock.minutesAgo(35), eid: "2").save(), true);
      expect(await SGV(value: 220, date: clock.minutesAgo(40), eid: "3").save(), true);

      await SGV.lastSGV.future;

      (trigger, active, smartSnooze) = alarm.alarmStatus();
      expect(trigger, true);
      expect(active, true);
      expect(smartSnooze, false);
      alarm.status();
    });

    test("PredictiveLowAlarm", () async {
      Alarm alarm = const PredictiveLowAlarm();
      var (trigger, active, smartSnooze) = alarm.alarmStatus();
      expect(trigger, false);
      expect(active, false);
      expect(smartSnooze, false);

      AlarmSettings().lowPredictionAlarm = true;
      AlarmSettings().lowMinutes = 10;
      TargetSettings().lowTarget = 72;

      expect(await SGV(value: 80, date: clock.now(), eid: "1").save(), true);
      expect(await SGV(value: 100, date: clock.minutesAgo(5), eid: "2").save(), true);
      expect(await SGV(value: 120, date: clock.minutesAgo(10), eid: "3").save(), true);

      await SGV.lastSGV.future;
      await SGV.last3Hours.future;
      PredictionService().predictionsSignal.recompute();

      (trigger, active, smartSnooze) = alarm.alarmStatus();
      expect(trigger, true);
      expect(active, true);
      expect(smartSnooze, false);
      alarm.status();
    });
  });
}
