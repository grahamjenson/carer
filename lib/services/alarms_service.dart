import 'dart:async';
import 'dart:io';

import 'package:carer/mappers/sql/sgv.dart';
import 'package:carer/models/clean_sgv.dart';
import 'package:carer/models/details/alarms/alarms.dart';
import 'package:carer/models/sql/events/alarm_event.dart';
import 'package:carer/services/alarms/brightness.dart';
import 'package:carer/services/alarms/player.dart';
import 'package:carer/services/app_lifecycle_service.dart';
import 'package:carer/services/settings/alarm_alert_settings.dart';
import 'package:carer/services/settings/alarm_settings.dart';
import 'package:carer/services/settings/secure_settings.dart';
import 'package:carer/services/settings/target_settings.dart';
import 'package:carer/services/settings/time_settings.dart';
import 'package:carer/services/timer_service.dart';
import 'package:carer/utils/env.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/utils/logs.dart';
import 'package:collection/collection.dart';
import 'package:signals/signals_flutter.dart';

const se = SetEquality();

class AlarmsService {
  static final AlarmsService _singleton = AlarmsService._();
  factory AlarmsService() => _singleton;
  AlarmPlayer? _player;
  IAlarmPlayer get player {
    if (Env.isTest) {
      return TestAlarmPlayer();
    }
    _player ??= AlarmPlayer();
    return _player!;
  }

  ASignal<AlarmSet> pendingAlarms = ASignal<AlarmSet>(AlarmSet({}), debugLabel: "PendingAlarms");
  ASignal<AlarmSet> alertingAlarms = ASignal<AlarmSet>(AlarmSet({}), debugLabel: "AlertingAlarms");

  AlarmsService._() {
    List<Signal> allSettingsSignals = [];
    allSettingsSignals.addAll(AlarmSettings().allSignals());
    allSettingsSignals.addAll(TargetSettings().allSignals());

    bool isCheckingAlarms = false;
    List<Signal> additionalDeps = [
      TimerService().fiveSecondSignal,
      AlarmAlertSettings().snoozeUntilSignal,
      SQLToSGV().writeSignal,
      AppLifecycleService().lastResumed,
      AppLifecycleService().lastChangeScreen
    ];

    List<Signal> checkAlarmsDependencies = allSettingsSignals + additionalDeps;

    // Calculate the alarms and then set Pending and Alerting Alarms values
    aeffect(() {
      try {
        var (newPendingAlarms, newAlertingAlarms) = calculateAlarms();
        pendingAlarms.value = newPendingAlarms;
        alertingAlarms.value = newAlertingAlarms;
      } catch (err) {
        alog("CheckAlarms: Error checking alarms: $err");
      }
      return true;
    }, debugLabel: "CheckAlarms", dependencies: checkAlarmsDependencies);

    // Alert when there are alarms to alert for.
    // When there is an alaerting alarm we can fix this.
    aeffect(
      () async {
        // is Checking alarms is a simple lock to stop multiple calls
        if (isCheckingAlarms) {
          return false;
        }
        isCheckingAlarms = true;

        try {
          // Do async so that one failure doesn't stop any other
          var audio = go(audioAlerts(alertingAlarms.value));
          var brightness = go(brightnessAlert(alertingAlarms.value));

          var (_, err) = await audio;

          if (err != null) {
            alog("Error playing audio alarms: $err");
          }

          (_, err) = await brightness;
          if (err != null) {
            alog("Error playing brightness alarms: $err");
          }
        } catch (err) {
          alog("AudioBrightnessAlarms: Error $err");
        } finally {
          isCheckingAlarms = false;
        }
        return true;
      },
      debugLabel: "AudioBrightnessAlarms",
      dependencies: [
        alertingAlarms,
        TimerService().tenSecondSignal,
      ],
    );

    // Auto Snooze Turn off
    aeffect(() {
      // This checks to see if we should wakeUpFromSnooze
      // Already not snoozing so can skip
      if (AlarmAlertSettings().snoozeDurationPeek == null) {
        return;
      }

      var (shouldWakeUpFromSnooze, reason, reasonString) = shouldWakeUp();

      if (shouldWakeUpFromSnooze) {
        alog("Snooze: $reasonString");
        AlarmAlertSettings().setSnoozeDurationSeconds(null, reason);
      }
    }, debugLabel: "WakingUpCalculation", dependencies: [
      TimerService().minuteSignal,
      pendingAlarms,
      CleanSGV.lastSGV,
    ]);

    // Writing the logs of alarms to the database
    AlarmSet pendingAlarmsCheck = AlarmSet({});
    AlarmSet alertingAlarmsCheck = AlarmSet({});

    aeffect(() async {
      if (pendingAlarmsCheck != pendingAlarms.value) {
        pendingAlarmsCheck = pendingAlarms.value;
        AlarmEvent.updateAlarmEvent(pendingAlarms.value, pendingAlarms.previousValue, AlarmStage.pending);
      }

      if (alertingAlarmsCheck != alertingAlarms.value) {
        alertingAlarmsCheck = alertingAlarms.value;
        AlarmEvent.updateAlarmEvent(alertingAlarms.value, alertingAlarms.previousValue, AlarmStage.alerting);
      }
    }, debugLabel: "WriteAlarmLogs");
  }

  (AlarmSet, AlarmSet) calculateAlarms() {
    var nightscoutNotConnected = !SecureSettings().nightscoutURLAndTokenSet();

    // If the app has only recently been resumed we give it time to warm up

    var recentlyOpened = AppLifecycleService().wasResumed2SecondsAgo;

    // Dont even Calculate alarms if Nightscout is not connected
    if (nightscoutNotConnected || recentlyOpened) {
      return (AlarmSet({}), AlarmSet({}));
    }

    Set<AlarmType> newPendingAlarms = {};
    Set<AlarmType> newActiveAlarms = {};

    var notSnoozing = AlarmAlertSettings().snoozeDuration == null;
    var allAlarmsEnabled = !AlarmSettings().disableAlarms;

    var notRecentlyScreenChange = !AppLifecycleService().wasScreenChanged5SecondsAgo;

    for (var alarm in AlarmType.values) {
      var (triggered, active, smartSnooze) = alarm.alarmStatus();

      var notSmartSnoozing = !smartSnooze;
      // Build the lists
      if (triggered) {
        newPendingAlarms.add(alarm);
      }

      // Do not add to active alarms if:
      // 1. Alarms are enabled
      // 2. Alarm is Triggered
      // 3. Alarm is Active
      // 4. App is Not snoozing
      // 5. Alarm is not smart snoozing
      // 6. App has not recently changed screen
      var addToActive = allAlarmsEnabled && triggered && active && notSnoozing && notSmartSnoozing && notRecentlyScreenChange;

      if (addToActive) {
        newActiveAlarms.add(alarm);
      }
    }

    // Filter out superceeding alarms
    newPendingAlarms = filterAlarms(newPendingAlarms);
    newActiveAlarms = filterAlarms(newActiveAlarms);

    // Set alarms that have been triggered
    return (AlarmSet(newPendingAlarms), AlarmSet(newActiveAlarms));
  }

  (bool, SnoozeReason, String) shouldWakeUp() {
    var (wakeUpForRange, reasonForRange, reasonStringForRange) = shouldWakeUpForRange();
    if (wakeUpForRange) {
      return (true, reasonForRange, reasonStringForRange);
    }

    var (wakeUpForUrgent, reasonForUrgent, reasonStringForUrgent) = shouldWakeUpForUrgent();
    if (wakeUpForUrgent) {
      return (true, reasonForUrgent, reasonStringForUrgent);
    }

    return (false, SnoozeReason.unknown, "");
  }

  (bool, SnoozeReason, String) shouldWakeUpForRange() {
    // This feature turns off snooze once the "danger is gone"
    if (!AlarmAlertSettings().enableWakeUpInRange) {
      return (false, SnoozeReason.unknown, "");
    }

    int mins = 20;
    Duration snoozeLastSet = AlarmAlertSettings().snoozeLastSet;

    if (snoozeLastSet.inMinutes < mins) {
      return (false, SnoozeReason.unknown, "Snooze Last Set ${snoozeLastSet.inMinutes} mins ago");
    }

    var lastSGV = CleanSGV.lastSGV.value;
    if (lastSGV == null) {
      return (false, SnoozeReason.unknown, "No SGV");
    }

    var lastReadings = CleanSGV.cleanAgoReadings(Duration(minutes: mins));
    if (lastReadings.isEmpty) {
      // We skip here but Wake Up On Urgent will wake up if no data
      return (false, SnoozeReason.unknown, "No Readings");
    }

    var everyReadingWithinRange = lastReadings.every((sgv) => sgv.withinRange);

    if (everyReadingWithinRange) {
      var reason = "All readings for last 20 minutes are in range, snooze last set: ${snoozeLastSet.inMinutes}; lastReadings: $lastReadings";
      return (true, SnoozeReason.wakeUpWhenInRange, reason);
    }
    return (false, SnoozeReason.unknown, "");
  }

  (bool, SnoozeReason, String) shouldWakeUpForUrgent() {
    // This feature turns off snooze if "danger increases"
    // 1. If you sleep a NON-URGENT Alarm, then an URGENT alarm happens, you should be woken up
    // 2. If you sleep a URGENT alarm then it should stay slept

    if (!AlarmAlertSettings().enableWakeUpWhenUrgent) {
      return (false, SnoozeReason.unknown, "");
    }

    if (!pendingAlarms.peek().containsUrgentAlarm()) {
      return (false, SnoozeReason.unknown, "No Urgent Pending Alarms");
    }

    var previouslyContainedUrgentAlarm = AlarmAlertSettings().snoozeUntilSignalAlarms.peek().containsUrgentAlarm();
    if (!previouslyContainedUrgentAlarm) {
      return (true, SnoozeReason.wakeUpWhenUrgent, "Urgent Alarm");
    }

    return (false, SnoozeReason.unknown, "");
  }

  Set<AlarmType> filterAlarms(Set<AlarmType> alarms) {
    // Remove and Stop test alarm if real alarm is present
    if (alarms.length > 1 && alarms.contains(AlarmType.test)) {
      alarms.remove(AlarmType.test);
      AlarmAlertSettings().testAlarm = false;
    }

    // remove low if urgent low
    if (alarms.contains(AlarmType.low) && alarms.contains(AlarmType.urgentLow)) {
      alarms.remove(AlarmType.low);
    }

    // remove high if urgent high
    if (alarms.contains(AlarmType.high) && alarms.contains(AlarmType.urgentHigh)) {
      alarms.remove(AlarmType.high);
    }
    return alarms;
  }

  Future<bool> audioAlerts(AlarmSet alarms) async {
    if (alarms.isEmpty || !AlarmAlertSettings().enableAudioAlarm) {
      alog("Stopping Audio Alarm: Setting is ${AlarmAlertSettings().enableAudioAlarm} Alarms are $alarms");
      var (playing, err) = await go(player.stopAlarm());
      if (playing == null || err != null) {
        alog("Error stopping alarm: $err");
      }
      return false;
    }

    alog("Playing AUDIO Alarms");
    var (playing, err) = await go(player.playAlarm());
    if (playing == null || err != null) {
      alog("Error playing alarm: $err");
    }
    return true;
  }

  Future<bool> brightnessAlert(AlarmSet alarms) async {
    if (!Platform.isIOS && !Platform.isAndroid) {
      return false;
    }

    if (!TimeSettings().isNight() || !AlarmAlertSettings().brightnessAdjustAtNight) {
      // Brightness only works at night
      alog("Stopping Brightness: Setting is ${AlarmAlertSettings().brightnessAdjustAtNight} Night is ${TimeSettings().isNight()}");
      BrightnessAlert().stop();
      return false;
    }

    if (alarms.isEmpty) {
      alog("Stopping Brightness Alarms");
      BrightnessAlert().stop();
      return false;
    }

    alog("Starting Brightness Alarms");
    BrightnessAlert().start();
    return true;
  }
}
