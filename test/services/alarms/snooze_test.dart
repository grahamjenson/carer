import 'package:carer/models/details/alarms/alarms.dart';
import 'package:carer/services/alarms_service.dart';
import 'package:carer/services/settings/alarm_alert_settings.dart';
import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test_utils.dart';

void main() async {
  agroup("Snoozing", () {
    atest("Should not recursive snooze with good numbers", () async {
      // Fake set an old snooze (slept for 10 minutes 30 minutes ago)
      AlarmsService();
      AlarmAlertSettings().snoozeUntilSignal.value = clock.ago(minutes: 20);
      AlarmAlertSettings().snoozeUntilSignal.lastSet = clock.ago(minutes: 30);
      expect(AlarmAlertSettings().snoozeDuration, isNull);

      // lots of good numbers
      await createSGVsInOrder([100, 100, 100, 100, 100, 100]);

      AlarmAlertSettings().setSnoozeDurationSeconds(1200, SnoozeReason.buttonPressed);

      expect(AlarmAlertSettings().isSnoozing(), true);
    });
  });

  agroup("WakeUpInRange", () {
    atest("Works ", () async {
      await createSGVsInOrder([100, 100, 100, 100, 100]);

      AlarmAlertSettings().snoozeUntilSignal.lastSet = clock.now().subtract(const Duration(minutes: 30));
      var (wakeUp, reason, reasonString) = AlarmsService().shouldWakeUpForRange();
      expect(wakeUp, true);
      expect(reason, SnoozeReason.wakeUpWhenInRange);
    });

    atest("When Snooze to early ", () async {
      await createSGVsInOrder([100, 100, 100, 100, 100]);

      AlarmAlertSettings().snoozeUntilSignal.lastSet = clock.now().subtract(const Duration(minutes: 10));
      var (wakeUp, reason, reasonString) = AlarmsService().shouldWakeUpForRange();
      expect(wakeUp, false);

      AlarmAlertSettings().snoozeUntilSignal.lastSet = clock.now().subtract(const Duration(minutes: 30));
      (wakeUp, reason, reasonString) = AlarmsService().shouldWakeUpForRange();
      expect(wakeUp, true);
    });

    atest("With Limited Data", () async {
      AlarmAlertSettings().snoozeUntilSignal.lastSet = clock.now().subtract(const Duration(minutes: 30));
      var (wakeUp, reason, reasonString) = AlarmsService().shouldWakeUpForRange();
      expect(wakeUp, false);

      await createSGVsInOrder([null, null, 100, null, null]);

      (wakeUp, reason, reasonString) = AlarmsService().shouldWakeUpForRange();
      expect(wakeUp, true);
    });
  });

  agroup("shouldWakeUpForUrgent", () {
    atest("Works", () async {
      // Alarm if previously sleept a high alarm, but now the alarms are urgent high
      AlarmAlertSettings().snoozeUntilSignalAlarms.value = AlarmSet({AlarmType.high});
      // Alarms triggers "now"
      AlarmsService().pendingAlarms.value = AlarmSet({AlarmType.urgentHigh}); // order here matters
      var (wakeUp, reason, reasonString) = AlarmsService().shouldWakeUpForUrgent();
      expect(wakeUp, true);

      // Dont alarm if previously slept an urgent alarm
      AlarmAlertSettings().snoozeUntilSignalAlarms.value = AlarmSet({AlarmType.urgentHigh});
      AlarmsService().pendingAlarms.value = AlarmSet({AlarmType.urgentHigh});
      (wakeUp, reason, reasonString) = AlarmsService().shouldWakeUpForUrgent();
      expect(wakeUp, false);
    });
  });
}
