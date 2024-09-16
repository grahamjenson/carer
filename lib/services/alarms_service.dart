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

  final Alarm _noDataAlarm = const NoDataAlarm();
  final Alarm _predictiveLowAlarm = const PredictiveLowAlarm();
  final Alarm _lowAlarm = const LowAlarm();
  final Alarm _urgentLowAlarm = const UrgentLowAlarm();
  final Alarm _highAlarm = const HighAlarm();
  final Alarm _urgentHighAlarm = const UrgentHighAlarm();
  final Alarm _fastDropAlarm = const FastDropAlarm();
  final Alarm _fastRiseAlarm = const FastRiseAlarm();

  final Alarm _carerBatteryAlarm = const CarerPhoneLowBatteryAlarm();
  final Alarm _t1dBatteryAlarm = const T1DPhoneLowBatteryAlarm();

  late final Set<Alarm> allAlarms = {
    // Target Alarms
    _urgentLowAlarm,
    _lowAlarm,
    _highAlarm,
    _urgentHighAlarm,
    // Rate Alarms
    _fastDropAlarm,
    _fastRiseAlarm,
    // No Data Alarm
    _noDataAlarm,
    // Predictive Alarms
    _predictiveLowAlarm,

    // Battery Alarms
    _carerBatteryAlarm,
    _t1dBatteryAlarm,
  };

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
    ];

    List<Signal> checkAlarmsDependencies = allSettingsSignals + additionalDeps;

    aeffect(() {
      try {
        var (newTriggeredAlarms, newActiveAlarms) = calculateAlarms();

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

    // Set to 15 seconds to offset the race condition on the 10 second timerSerivce signal
    AlarmAlertSettings().sleepDurationSeconds = 15;
    aeffect(
      () {
        // Sleep for a second or two when opened
        if (Platform.isAndroid || Platform.isIOS) {
          if (AlarmAlertSettings().sleepDurationPeek == null) {
            AlarmAlertSettings().sleepDurationSeconds = 10;
          }
        }
      },
      debugLabel: "SleepOnLastResumed",
      dependencies: [AppLifecycleService().lastResumed],
    );
  }

  (Set<Alarm>, Set<Alarm>) calculateAlarms() {
    var notSleeping = AlarmAlertSettings().sleepDuration == null;
    Set<Alarm> newTriggeredAlarms = {};
    Set<Alarm> newActiveAlarms = {};

    var disabledAllAlarms = AlarmSettings().disableAlarms;

    for (var alarm in allAlarms) {
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
    if (alarms.contains(_lowAlarm) && alarms.contains(_predictiveLowAlarm)) {
      alarms.remove(_predictiveLowAlarm);
    }

    // remove low if urgent low
    if (alarms.contains(_lowAlarm) && alarms.contains(_urgentLowAlarm)) {
      alarms.remove(_lowAlarm);
    }

    // remove high if urgent high
    if (alarms.contains(_highAlarm) && alarms.contains(_urgentHighAlarm)) {
      alarms.remove(_highAlarm);
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
      print("Brightness: Not night");
      BrightnessAlert().stop();
      return false;
    }

    if (!AlarmAlertSettings().brightnessAdjustAtNight) {
      alog("Stopping Brightness Alarms Turned off");
      print("Brightness: Stopping not enabled");
      BrightnessAlert().stop();
      return false;
    }

    if (alarms.isEmpty) {
      alog("Stopping Brightness Alarms");
      print("Brightness: empty");
      BrightnessAlert().stop();
      return false;
    }

    alog("Starting Brightness Alarms");
    print("Brightness: starting");
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
