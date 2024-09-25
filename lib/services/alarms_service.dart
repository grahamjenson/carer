import 'dart:async';
import 'dart:io';

import 'package:carer/mappers/sql_mappers.dart';
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

  ASignal<AlarmSet> triggeredAlarms = ASignal<AlarmSet>(AlarmSet({}), debugLabel: "TriggeredAlarms");
  ASignal<AlarmSet> activeAlarms = ASignal<AlarmSet>(AlarmSet({}), debugLabel: "ActiveAlarms");

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
      AlarmAlertSettings().sleepUntilSignal,
      SQLToSGV().writeSignal,
      AppLifecycleService().lastResumed,
      AppLifecycleService().lastChangeScreen
    ];

    List<Signal> checkAlarmsDependencies = allSettingsSignals + additionalDeps;

    aeffect(() {
      try {
        var (newTriggeredAlarms, newActiveAlarms) = calculateAlarms();

        // If the app has only recently been resumed or a screen changed, we wipe all the active alarms
        // because we want to give the app some time ot "warm up" and if the user is doing something give them time to finish
        if (AppLifecycleService().wasRecentlyResumed || AppLifecycleService().wasRecentlyScreenChanged) {
          newActiveAlarms = <Alarm>{};
        }

        triggeredAlarms.value = AlarmSet(newTriggeredAlarms);
        activeAlarms.value = AlarmSet(newActiveAlarms);
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
          var audio = go(audioAlerts(activeAlarms.value));
          var brightness = go(brightnessAlert(activeAlarms.value));

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
        activeAlarms,
        TimerService().tenSecondSignal,
      ],
    );
  }

  (Set<Alarm>, Set<Alarm>) calculateAlarms() {
    var notSleeping = AlarmAlertSettings().sleepDuration == null;
    Set<Alarm> newTriggeredAlarms = {};
    Set<Alarm> newActiveAlarms = {};

    var disabledAllAlarms = AlarmSettings().disableAlarms;

    for (var alarm in Alarm.values) {
      var (triggered, active, smartSnooze) = alarm.alarmStatus();

      // Build the lists
      if (triggered) {
        newTriggeredAlarms.add(alarm);
      }

      var addToActive = !disabledAllAlarms && triggered && active && notSleeping && !(smartSnooze);

      // If Sleeping do not add
      if (addToActive) {
        newActiveAlarms.add(alarm);
      }
    }
    // Filter out doubles of alarms
    newTriggeredAlarms = filterAlarms(newTriggeredAlarms);
    newActiveAlarms = filterAlarms(newActiveAlarms);

    // Set alarms that have been triggered
    return (newTriggeredAlarms, newActiveAlarms);
  }

  Set<Alarm> filterAlarms(Set<Alarm> alarms) {
    // Remove predictive low if actually low
    if (alarms.contains(Alarm.low) && alarms.contains(Alarm.predictiveLow)) {
      alarms.remove(Alarm.predictiveLow);
    }

    // remove low if urgent low
    if (alarms.contains(Alarm.low) && alarms.contains(Alarm.urgentLow)) {
      alarms.remove(Alarm.low);
    }

    // remove high if urgent high
    if (alarms.contains(Alarm.high) && alarms.contains(Alarm.urgentHigh)) {
      alarms.remove(Alarm.high);
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

  // Sleep

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
