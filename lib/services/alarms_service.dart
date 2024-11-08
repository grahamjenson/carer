import 'dart:async';
import 'dart:io';

import 'package:carer/mappers/sql/logs/alarms_log.dart';
import 'package:carer/mappers/sql/sgv.dart';
import 'package:carer/models/details/alarms/alarms.dart';
import 'package:carer/models/sql/logs/alarm_logs.dart';
import 'package:carer/services/alarms/brightness.dart';
import 'package:carer/services/alarms/player.dart';
import 'package:carer/services/app_lifecycle_service.dart';
import 'package:carer/services/settings/alarm_alert_settings.dart';
import 'package:carer/services/settings/alarm_settings.dart';
import 'package:carer/services/settings/target_settings.dart';
import 'package:carer/services/settings/time_settings.dart';
import 'package:carer/services/timer_service.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/utils/logs.dart';
import 'package:clock/clock.dart';
import 'package:collection/collection.dart';
import 'package:signals/signals_flutter.dart';

const se = SetEquality();

class AlarmsService {
  static final AlarmsService _singleton = AlarmsService._();
  factory AlarmsService() => _singleton;
  final AlarmPlayer player = AlarmPlayer();

  final ASignal<bool> _testAlarmPlayingSignal = ASignal<bool>(false, debugLabel: "TestAlarmPlaying");
  bool get testAlarmPlaying => _testAlarmPlayingSignal.value;
  set testAlarmPlaying(bool value) => _testAlarmPlayingSignal.value = value;

  ASignal<AlarmSet> pendingAlarms = ASignal<AlarmSet>(AlarmSet({}), debugLabel: "PendingAlarms");
  ASignal<AlarmSet> alertingAlarms = ASignal<AlarmSet>(AlarmSet({}), debugLabel: "AlertingAlarms");

  AlarmsService._() {
    List<Signal> allSettingsSignals = [];
    allSettingsSignals.addAll(AlarmSettings().allSignals());
    allSettingsSignals.addAll(AlarmAlertSettings().allSignals());
    allSettingsSignals.addAll(TargetSettings().allSignals());

    aeffect(() async {
      // Stop test alarm
      await stopTestAlarm();
      return false;
    }, debugLabel: "StopTestAlarmWhenSettingsChange", dependencies: allSettingsSignals);

    bool isCheckingAlarms = false;
    List<Signal> additionalDeps = [
      TimerService().tenSecondSignal,
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

        // If the app has only recently been resumed or a screen changed, we wipe all the active alarms
        // because we want to give the app some time ot "warm up" and if the user is doing something give them time to finish
        if (AppLifecycleService().wasResumed10SecondsAgo || AppLifecycleService().wasRecentlyScreenChanged) {
          newAlertingAlarms = <AlarmType>{};
        }

        pendingAlarms.value = AlarmSet(newPendingAlarms);
        alertingAlarms.value = AlarmSet(newAlertingAlarms);
      } catch (err) {
        alog("CheckAlarms: Error checking alarms: $err");
      }
      return true;
    }, debugLabel: "CheckAlarms", dependencies: checkAlarmsDependencies);

    // Alert when there are alarms to alert for.
    // When there is an alaerting alarm we can fix this.
    aeffect(
      () async {
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
      // The reason for this feature is that snooze should be turned off as quickly as possible once the "danger is gone"
      // There are two reasons to snooze
      // 1. There is an alarm
      // 2. There is assumed to be an alarm

      if (!AlarmAlertSettings().enableAutoSnoozeOff) {
        return;
      }
      if (AlarmAlertSettings().snoozeDuration == null) {
        return;
      }

      int mins = 20;
      Duration snoozeLastSet = AlarmAlertSettings().snoozeLastSet;
      Duration pendingAlarmsLastSet = pendingAlarms.lastSetAgo;
      int pendingAlarmsSize = pendingAlarms.value.length;

      bool pendingAlarmsBeenEmptyForMins = pendingAlarmsLastSet.inMinutes > mins && pendingAlarmsSize == 0;

      if (snoozeLastSet.inMinutes > mins && pendingAlarmsBeenEmptyForMins) {
        var reason =
            "Auto Snooze Off Last Snooze ${snoozeLastSet.inMinutes} mins ago, Pending Alarms ($pendingAlarmsSize) last changed ${pendingAlarmsLastSet.inMinutes} mins ago";
        alog("Snooze: $reason");
        AlarmAlertSettings().setSnoozeDurationSeconds(null, reason);
      }
    }, debugLabel: "AutoSnoozeOff", dependencies: [TimerService().minuteSignal]);

    // Writing the logs of alarms to the database
    AlarmSet pendingAlarmsCheck = AlarmSet({});
    AlarmSet alertingAlarmsCheck = AlarmSet({});

    aeffect(() async {
      if (pendingAlarmsCheck != pendingAlarms.value) {
        pendingAlarmsCheck = pendingAlarms.value;
        updateAlarmLog(pendingAlarms.value, pendingAlarms.previousValue, AlarmStage.pending);
      }

      if (alertingAlarmsCheck != alertingAlarms.value) {
        alertingAlarmsCheck = alertingAlarms.value;
        updateAlarmLog(alertingAlarms.value, alertingAlarms.previousValue, AlarmStage.alerting);
      }
    }, debugLabel: "WriteAlarmLogs");
  }

  (Set<AlarmType>, Set<AlarmType>) calculateAlarms() {
    var notSnoozing = AlarmAlertSettings().snoozeDuration == null;
    Set<AlarmType> newPendingAlarms = {};
    Set<AlarmType> newActiveAlarms = {};

    var disabledAllAlarms = AlarmSettings().disableAlarms;

    for (var alarm in AlarmType.values) {
      var (triggered, active, smartSnooze) = alarm.alarmStatus();

      // Build the lists
      if (triggered) {
        newPendingAlarms.add(alarm);
      }

      var addToActive = !disabledAllAlarms && triggered && active && notSnoozing && !(smartSnooze);

      if (addToActive) {
        newActiveAlarms.add(alarm);
      }
    }
    // Filter out doubles of alarms
    newPendingAlarms = filterAlarms(newPendingAlarms);
    newActiveAlarms = filterAlarms(newActiveAlarms);

    // Set alarms that have been triggered
    return (newPendingAlarms, newActiveAlarms);
  }

  Set<AlarmType> filterAlarms(Set<AlarmType> alarms) {
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

  Future<void> stopTestAlarm() async {
    var (stopped, err) = await go(player.stopTestAlarm());
    if (stopped == null || err != null) {
      alog("Error stopping test alarm: $err");
      return;
    }
    alog("Stopped test alarm");
    testAlarmPlaying = false;
  }

  Future<void> playTestAlarm() async {
    var (playing, err) = await go(player.playTestAlarm());
    if (playing == null || err != null) {
      alog("Error playing test alarm: $err");
      return;
    }
    alog("Playing test alarm");
    testAlarmPlaying = true;
  }

  Future<void> updateAlarmLog(AlarmSet alarms, AlarmSet? previousAlarms, AlarmStage stage) async {
    var newAlarms = alarms;
    var removedAlarms = AlarmSet({});
    if (previousAlarms != null) {
      newAlarms = alarms.difference(previousAlarms);
      removedAlarms = previousAlarms.difference(alarms);
    }

    // Write the alarms

    // // if there is a new value then create a new alarm
    for (var newAlarm in newAlarms) {
      var log = AlarmLog(
        type: newAlarm,
        conditions: newAlarm.conditions(),
        stage: stage,
        startDate: clock.now(),
      );
      await SQLToAlarmLogs().save(log);
    }

    // If there is a removed Value then remove the alarm
    for (var removedAlarm in removedAlarms) {
      var log = await SQLToAlarmLogs().findUnfinishedAlarmOfTypeAndStage(removedAlarm, stage);
      if (log == null) {
        continue;
      }
      log.endDate = clock.now();
      await SQLToAlarmLogs().save(log);
    }
  }
}
