import 'package:carer/models/details/alarms/alarms.dart';
import 'package:carer/services/settings/alarm_settings.dart';
import 'package:carer/services/settings/target_settings.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test_utils.dart';

void main() async {
  agroup("Alarms", () {
    atest("HighAlarm", () async {
      AlarmType alarm = AlarmType.high;
      var (trigger, active, smartSnooze) = alarm.alarmStatus();
      expect(trigger, false);
      expect(active, true);
      expect(smartSnooze, false);

      AlarmSettings().highMinutes = 10;
      TargetSettings().highTarget = 180;

      await createSGVsInOrder([220, 200, 185]);

      (trigger, active, smartSnooze) = alarm.alarmStatus();
      expect(trigger, true);
      expect(active, true);
      expect(smartSnooze, true);

      alarm.shortSummary();
    });

    atest("LowAlarm", () async {
      AlarmType alarm = AlarmType.low;
      var (trigger, active, smartSnooze) = alarm.alarmStatus();
      expect(trigger, false);
      expect(active, true);
      expect(smartSnooze, false);

      TargetSettings().lowTarget = 72;

      await createSGVsInOrder([50, 60, 70]);

      (trigger, active, smartSnooze) = alarm.alarmStatus();
      expect(trigger, true);
      expect(active, true);
      expect(smartSnooze, false);
      alarm.shortSummary();
    });

    atest("UrgentHighAlarm", () async {
      AlarmType alarm = AlarmType.urgentHigh;
      var (trigger, active, smartSnooze) = alarm.alarmStatus();
      expect(trigger, false);
      expect(active, true);
      expect(smartSnooze, false);

      TargetSettings().highUrgent = 180;

      await createSGVsInOrder([220, 200, 185]);

      (trigger, active, smartSnooze) = alarm.alarmStatus();
      expect(trigger, true);
      expect(active, true);
      expect(smartSnooze, false);
      alarm.shortSummary();
    });

    atest("UrgentLowAlarm", () async {
      AlarmType alarm = AlarmType.urgentLow;
      var (trigger, active, smartSnooze) = alarm.alarmStatus();
      expect(trigger, false);
      expect(active, true);
      expect(smartSnooze, false);

      TargetSettings().lowUrgent = 72;

      await createSGVsInOrder([50, 60, 70]);

      (trigger, active, smartSnooze) = alarm.alarmStatus();
      expect(trigger, true);
      expect(active, true);
      expect(smartSnooze, false);
      alarm.shortSummary();
    });

    atest("FastRiseAlarm", () async {
      AlarmType alarm = AlarmType.fastRise;
      var (trigger, active, smartSnooze) = alarm.alarmStatus();
      expect(trigger, false);
      expect(active, false);
      expect(smartSnooze, false);

      AlarmSettings().fastRiseAlarmMinutes = 10;
      TargetSettings().fastRiseDelta = 10;

      await createSGVsInOrder([170, 181, 192]);

      (trigger, active, smartSnooze) = alarm.alarmStatus();
      expect(trigger, true);
      expect(active, true);
      expect(smartSnooze, false);
      alarm.shortSummary();
    });

    atest("FastDropAlarm", () async {
      AlarmType alarm = AlarmType.fastDrop;
      var (trigger, active, smartSnooze) = alarm.alarmStatus();
      expect(trigger, false);
      expect(active, false);
      expect(smartSnooze, false);

      AlarmSettings().fastDropAlarmMinutes = 10;
      TargetSettings().fastDropDelta = -10;

      await createSGVsInOrder([150, 130, 110]);

      (trigger, active, smartSnooze) = alarm.alarmStatus();
      expect(trigger, true);
      expect(active, true);
      expect(smartSnooze, false);
      alarm.shortSummary();
    });

    atest("NoDataAlarm", (DateTime now) async {
      AlarmType alarm = AlarmType.noData;
      var (trigger, active, smartSnooze) = alarm.alarmStatus();
      expect(trigger, false);
      expect(active, false);
      expect(smartSnooze, false);

      AlarmSettings().noDataAlarmMinutes = 20;

      await createSGVsInOrder([220, 200, 187], now: now.subtract(min30));

      (trigger, active, smartSnooze) = alarm.alarmStatus();

      expect(trigger, true);
      expect(active, true);
      expect(smartSnooze, false);
      alarm.shortSummary();

      await createSGVsInOrder([220, 200, 187], now: now);
      (trigger, active, smartSnooze) = alarm.alarmStatus();

      expect(trigger, false);
      expect(active, true);
      expect(smartSnooze, false);
    });

    atest("PredictiveLowAlarm", () async {
      AlarmType alarm = AlarmType.low;
      var (trigger, active, smartSnooze) = alarm.alarmStatus();
      expect(trigger, false);
      expect(active, true);
      expect(smartSnooze, false);

      TargetSettings().lowTarget = 72;

      await createSGVsInOrder([120, 100, 80]);

      (trigger, active, smartSnooze) = alarm.alarmStatus();
      expect(trigger, true);
      expect(active, true);
      expect(smartSnooze, false);
      alarm.shortSummary();
    });
  });
}
