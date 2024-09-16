import 'dart:async';
import 'dart:io';

import 'package:carer/mappers/sql_mappers.dart';
import 'package:carer/services/alarms/alarms.dart';
import 'package:carer/services/alarms/brightness.dart';
import 'package:carer/services/alarms/player.dart';
import 'package:carer/services/settings/alarm_alert_settings.dart';
import 'package:carer/services/settings/alarm_settings.dart';
import 'package:carer/services/settings/target_settings.dart';
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

  // Start with a sleep, to give time for the app to catch up
  final ASignal<DateTime?> sleepUntilSignal = ASignal(null, debugLabel: "sleepUntil");

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
      sleepUntilSignal,
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
    sleepDurationSeconds = 15;
  }

  (Set<Alarm>, Set<Alarm>) calculateAlarms() {
    var notSleeping = sleepDuration == null;
    Set<Alarm> newTriggeredAlarms = {};
    Set<Alarm> newActiveAlarms = {};

    var disabledAllAlarms = AlarmSettings().disableAlarms;
    var smartSnoozeOn = AlarmAlertSettings().smartSnooze;
    for (var alarm in allAlarms) {
      var (triggered, active, smartSnooze) = alarm.alarmStatus();

      // Build the lists
      if (triggered) {
        newTriggeredAlarms.add(alarm);
      }

      var addToActive = !disabledAllAlarms && triggered && active && notSleeping && !(smartSnoozeOn && smartSnooze);

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

    if (!AlarmAlertSettings().brightnessAdjust) {
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

  Timer? sleepTimer;
  Duration? get sleepDuration {
    if (sleepUntilSignal.value == null) {
      return null;
    }
    var duration = sleepUntilSignal.value!.difference(clock.now());

    if (duration.isNegative) {
      // Assign duration null to cause updates
      sleepUntilSignal.value = null;
      return null;
    }

    return duration;
  }

  set sleepDurationSeconds(int? value) {
    if (sleepTimer != null) {
      sleepTimer!.cancel(); // Always cancel
    }

    if (value == null) {
      sleepUntilSignal.value = null;
      return;
    }

    sleepTimer = Timer(Duration(seconds: value), () {
      sleepUntilSignal.value = null;
    });

    sleepUntilSignal.value = clock.now().add(Duration(seconds: value));
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
