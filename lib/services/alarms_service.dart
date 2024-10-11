import 'dart:async';
import 'dart:io';

import 'package:carer/mappers/sql/sgv.dart';
import 'package:carer/services/alarms/alarms.dart';
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

    aeffect(() {
      try {
        var (newPendingAlarms, newAlertingAlarms) = calculateAlarms();

        // If the app has only recently been resumed or a screen changed, we wipe all the active alarms
        // because we want to give the app some time ot "warm up" and if the user is doing something give them time to finish
        if (AppLifecycleService().wasRecentlyResumed || AppLifecycleService().wasRecentlyScreenChanged) {
          newAlertingAlarms = <AlarmType>{};
        }

        pendingAlarms.value = AlarmSet(newPendingAlarms);
        alertingAlarms.value = AlarmSet(newAlertingAlarms);
      } catch (err) {
        alog("CheckAlarms: Error checking alarms: $err");
      }
      return true;
    }, debugLabel: "CheckAlarms", dependencies: checkAlarmsDependencies);

    aeffect(
      () async {
        if (isCheckingAlarms) {
          return false;
        }
        isCheckingAlarms = true;

        try {
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
    if (alarms.isEmpty) {
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

    if (!TimeSettings().isNight()) {
      // Brightness only works at night
      BrightnessAlert().stop();
      return false;
    }

    if (!AlarmAlertSettings().brightnessAdjustAtNight) {
      alog("Stopping Brightness Alarms Turned off");
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
}
