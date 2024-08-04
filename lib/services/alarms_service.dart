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
    var (newTriggeredAlarms, newActiveAlarms) = await calculateAlarms();

    if (tooSoon()) {
      // If it was recently resumed it might cause bad alarm data
      newActiveAlarms = {};
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
    // Filter out doubles of alarms
    newTriggeredAlarms = filterAlarms(newTriggeredAlarms);
    newActiveAlarms = filterAlarms(newActiveAlarms);

    alog("Triggered Alarms: $newTriggeredAlarms\tActive Alarms: $newActiveAlarms");

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
