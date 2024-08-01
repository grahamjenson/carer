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

  final Signal<DateTime?> sleepUntilSignal = Signal(null, debugLabel: "sleepUntil");

  late final Set<Alarm> allAlarms = {
    // Target Alarms
    const UrgentLowAlarm(),
    const LowAlarm(),
    const HighAlarm(),
    const UrgentHighAlarm(),
    // Rate Alarms
    const FastDropAlarm(),
    const FastRiseAlarm(),
    // No Data Alarm
    const NoDataAlarm(),
    // Predictive Alarms
    const PredictiveLowAlarm(),
  };

  final Signal<bool> _testAlarmPlayingSignal = Signal<bool>(false, debugLabel: "TestAlarmPlaying");
  bool get testAlarmPlaying => _testAlarmPlayingSignal.value;
  set testAlarmPlaying(bool value) => _testAlarmPlayingSignal.value = value;

  Signal<Set<Alarm>> triggeredAlarms = Signal<Set<Alarm>>({}, debugLabel: "TriggeredAlarms");
  Signal<Set<Alarm>> activeAlarms = Signal<Set<Alarm>>({}, debugLabel: "ActiveAlarms");

  AlarmsService._() {
    List<Signal> allSettingsSignals = AlarmSettings().allSignals() + AlarmAlertSettings().allSignals() + TargetSettings().allSignals();

    aeffect(() async {
      // Stop test alarm
      await stopTestAlarm();
      return false;
    }, debugLabel: "StopTestAlarmWhenSettingsChange", dependencies: allSettingsSignals);

    bool isCheckingAlarms = false;
    List<Signal> checkAlarmsDependencies = allSettingsSignals +
        [
          TimerService().tenSecondSignal,
          sleepUntilSignal,
          SQLToSGV().writeSignal,
        ];

    aeffect(() async {
      // Only execute this one at a time
      if (isCheckingAlarms) {
        alog("CheckAlarms: Skipping check alarms, already checking");
        return false;
      }
      isCheckingAlarms = true;

      alog("CheckAlarms: checking alarms");
      try {
        await _checkAlarms();
      } catch (err) {
        alog("CheckAlarms: Error checking alarms: $err");
      } finally {
        alog("CheckAlarms: Finished checking alarms");
        isCheckingAlarms = false;
      }
      return true;
    }, debugLabel: "CheckAlarms", dependencies: checkAlarmsDependencies);
  }

  Future<bool> _checkAlarms() async {
    Set<Alarm> newTriggeredAlarms = {};
    Set<Alarm> newActiveAlarms = {};

    if (!tooSoon()) {
      // If it was resumed recently we want to turn off all alarms, otherwise check alarms
      (newTriggeredAlarms, newActiveAlarms) = await calculateAlarms();
    }

    triggeredAlarms.value = newTriggeredAlarms;
    activeAlarms.value = newActiveAlarms;

    var (_, err) = await go(audioAlerts(newActiveAlarms));
    if (err != null) {
      alog("Error checking audio alarms: $err");
    }

    (_, err) = await go(brightnessAlert(newActiveAlarms));
    if (err != null) {
      alog("Error checking brightness alarms: $err");
    }

    return true;
  }

  bool tooSoon() {
    var lastResumed = AppLifecycleService().lastResumed.peek();
    // Skip if lastResumed less than 3 seconds ago
    if (lastResumed.isAfter(clock.secondsAgo(1))) {
      alog("CheckAlarms: Skipping since resumed less than 1 seconds ago");
      return true;
    }
    return false;
  }

  Future<(Set<Alarm>, Set<Alarm>)> calculateAlarms() async {
    var notSleeping = sleepUntilSignal.value == null;

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

      // If Sleeping do not add
      if (!disabledAllAlarms && triggered && active && notSleeping && !(smartSnoozeOn && smartSnooze)) {
        newActiveAlarms.add(alarm);
      }
    }

    alog("Triggered Alarms: $newTriggeredAlarms\tActive Alarms: $newActiveAlarms");

    // Set alarms that have been triggered

    return (newTriggeredAlarms, newActiveAlarms);
  }

  Future<bool> audioAlerts(Set<Alarm> alarms) async {
    if (alarms.isEmpty) {
      alog("Stopping AUDIO Alarms");
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

  Future<bool> brightnessAlert(Set<Alarm> alarms) async {
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
    return sleepUntilSignal.value!.difference(clock.now());
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
