import 'dart:async';

import 'package:carer/services/alarms/alarms.dart';
import 'package:carer/services/alarms/player.dart';
import 'package:carer/services/settings/alarm_alert_settings.dart';
import 'package:carer/services/settings/alarm_settings.dart';
import 'package:carer/services/settings/target_settings.dart';
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

  final Signal<DateTime?> _sleepUntilSignal = Signal(null, debugLabel: "sleepUntil");

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

  AlarmsService._() {
    aeffect(() {
      // When an alarm settings
      var sigs = AlarmSettings().allValues();
      var aas = AlarmAlertSettings().allValues();
      // When a Target setting changes
      var tigs = TargetSettings().allValues();
      // Stop test alarm
      stopTestAlarm();
    }, debugLabel: "StopTestAlarmWhenSettingsChange");

    aeffect(() {
      checkAlarms();
      alog("checking alarms");
    }, debugLabel: "CheckAlarms");
  }

  final Signal<Set<Alarm>> _triggeredAlarmsSignal = Signal(<Alarm>{}, debugLabel: "triggeredAlarms");
  Set<Alarm> get triggeredAlarms => _triggeredAlarmsSignal.value;
  set triggeredAlarms(Set<Alarm> value) {
    if (se.equals(value, _triggeredAlarmsSignal.value)) {
      return;
    }
    _triggeredAlarmsSignal.value = value;
  }

  final Signal<Set<Alarm>> _activeAlarmsSignal = Signal(<Alarm>{}, debugLabel: "activeAlarms");
  Set<Alarm> get activeAlarms => _activeAlarmsSignal.value;
  set activeAlarms(Set<Alarm> value) {
    if (se.equals(value, _activeAlarmsSignal.value)) {
      return;
    }
    _activeAlarmsSignal.value = value;
  }

  // Sleep

  bool get notSleeping {
    return _sleepUntilSignal.value == null;
  }

  Timer? sleepTimer;
  Duration? get sleepDuration {
    if (_sleepUntilSignal.value == null) {
      return null;
    }
    return _sleepUntilSignal.value!.difference(clock.now());
  }

  set sleepDurationSeconds(int? value) {
    if (sleepTimer != null) {
      sleepTimer!.cancel(); // Always cancel
    }

    if (value == null) {
      _sleepUntilSignal.value = null;
      return;
    }

    sleepTimer = Timer(Duration(seconds: value), () {
      _sleepUntilSignal.value = null;
    });

    _sleepUntilSignal.value = clock.now().add(Duration(seconds: value));
  }

  void checkAlarms() async {
    var newTriggeredAlarms = <Alarm>{};
    var newActiveAlarms = <Alarm>{};
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

    // Set alarms that have been triggered
    triggeredAlarms = newTriggeredAlarms;
    activeAlarms = newActiveAlarms;

    // Set alarms
    if (activeAlarms.isEmpty) {
      var (playing, err) = await go(player.stopAlarm());
      if (playing == null || err != null) {
        alog("Error stopping alarm: $err");
      }
    } else {
      var (playing, err) = await go(player.playAlarm());
      if (playing == null || err != null) {
        alog("Error playing alarm: $err");
      }
    }
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
