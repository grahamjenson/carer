import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:carer/services/alarms/alarms.dart';
import 'package:carer/services/settings/alarm_settings.dart';
import 'package:carer/services/settings/target_settings.dart';
import 'package:clock/clock.dart';
import 'package:collection/collection.dart';
import 'package:flutter_volume_controller/flutter_volume_controller.dart';
import 'package:signals/signals_flutter.dart';

const se = SetEquality();

class AlarmsService {
  static final AlarmsService _singleton = AlarmsService._();
  factory AlarmsService() => _singleton;
  late final Set<Alarm> allAlarms = {
    const UrgentLowAlarm(),
    const LowAlarm(),
    const HighAlarm(),
    const UrgentHighAlarm(),
    //
    const FastDropAlarm(),
    const FastRiseAlarm(),
    //
    const NoDataAlarm(),
    //
    const PredictiveLowAlarm(),
  };

  Signal<bool> get _testAlarmPlayingSignal => Signal<bool>(false);
  bool get testAlarmPlaying => _testAlarmPlayingSignal.value;
  set testAlarmPlaying(bool value) => _testAlarmPlayingSignal.value = value;

  AlarmsService._() {
    effect(() {
      try {
        // When an alarm settings
        var sigs = AlarmSettings().allValues();
        // When a Target setting changes
        var tigs = TargetSettings().allValues();
        // Stop test alarm
        stopTestAlarm();
      } catch (e) {
        print("Error in StopTestAlarm AlarmsService effect: $e");
      }
    }, debugLabel: "StopTestAlarm");

    effect(() {
      try {
        checkAlarms();
      } catch (e) {
        print("Error in CheckAlarms AlarmsService effect: $e");
      }
    }, debugLabel: "CheckAlarms");
  }

  String get alarmFile {
    return (AlarmSettings().alarmAsset).asset;
  }

  final Signal<Set<Alarm>> _triggeredAlarmsSignal = Signal(<Alarm>{});
  Set<Alarm> get triggeredAlarms => _triggeredAlarmsSignal.value;
  set triggeredAlarms(Set<Alarm> value) {
    if (se.equals(value, _triggeredAlarmsSignal.value)) {
      return;
    }
    _triggeredAlarmsSignal.value = value;
  }

  final Signal<Set<Alarm>> _activeAlarmsSignal = Signal(<Alarm>{});
  Set<Alarm> get activeAlarms => _activeAlarmsSignal.value;
  set activeAlarms(Set<Alarm> value) {
    if (se.equals(value, _activeAlarmsSignal.value)) {
      return;
    }
    _activeAlarmsSignal.value = value;
  }

  // Minutes of sleep time
  final Signal<DateTime> _sleepUntilSignal = Signal(clock.daysAgo(1));

  bool get notSleeping {
    return sleepDuration.inSeconds <= 0;
  }

  Duration get sleepDuration => _sleepUntilSignal.value.difference(clock.now());
  set sleepDurationSeconds(int value) {
    _sleepUntilSignal.value = clock.now().add(Duration(seconds: value));
  }

  final alarmPlayer = AudioPlayer();
  final testPlayer = AudioPlayer();
  final audioContext = const AudioContext(
    android: AudioContextAndroid(),
    iOS: AudioContextIOS(),
  );

  double? originalVolume;

  void checkAlarms() async {
    var newTriggeredAlarms = <Alarm>{};
    var newActiveAlarms = <Alarm>{};
    var disabledAllAlarms = AlarmSettings().disableAlarms;
    var smartSnooze = AlarmSettings().smartSnooze;
    for (var alarm in allAlarms) {
      var triggered = alarm.trigger();
      var active = alarm.active();
      var alarmSmartSnooze = alarm.smartSnooze();

      // Build the lists

      if (triggered) {
        newTriggeredAlarms.add(alarm);
      }
      // If Sleeping do not add
      if (!disabledAllAlarms &&
          triggered &&
          active &&
          notSleeping &&
          !(smartSnooze && alarmSmartSnooze)) {
        newActiveAlarms.add(alarm);
      }
    }

    // Set alarms that have been triggered
    triggeredAlarms = newTriggeredAlarms;
    activeAlarms = newActiveAlarms;

    // Set alarms
    if (activeAlarms.isEmpty) {
      stopAlarm(alarmPlayer);
    } else {
      playAlarm(alarmPlayer);
    }
  }

  Future<bool> stopAlarm(AudioPlayer player) async {
    if (player.state == PlayerState.playing) {
      await player.stop();
      resetOriginalVolume();
      return true;
    }
    return false;
  }

  Future<void> playAlarm(AudioPlayer player) async {
    if (player.state == PlayerState.playing) {
      return;
    }

    var override = AlarmSettings().volumeOveride;
    var progression = AlarmSettings().volumeProgressionSeconds != -1;

    // TODO: Check if the system supports override (e.g. web), if not set to false

    // There are 4 possible states here:
    // 1. No override, no progression, just play alarm
    // 2. no override with Progression, play alarm but increase volume using the player (so we dont touch the system volume)
    // 3. Override with no progression, in which we set the volume to override and then play alarm (when is stops we reset volume)
    // 4. Override with progression, in which case we play the alarm and it progressivly get louder
    if (!override && !progression) {
      return playAlarmWithoutOverrideWithoutProgression(player);
    } else if (!override && progression) {
      return playAlarmWithoutOverrideWithProgression(player);
    } else if (override && !progression) {
      return playAlarmWithOverrideWithoutProgression(player);
    } else if (override && progression) {
      return playAlarmWithOverrideWithProgression(player);
    }
  }

  Future<void> playerPlay(AudioPlayer player, {double? volume}) {
    return player.play(
      AssetSource(alarmFile),
      ctx: audioContext,
      volume: volume,
    );
  }

  Future<void> playAlarmWithoutOverrideWithoutProgression(
      AudioPlayer player) async {
    return playerPlay(player);
  }

  Future<void> playAlarmWithoutOverrideWithProgression(
      AudioPlayer player) async {
    int progressionSeconds = AlarmSettings().volumeProgressionSeconds;

    await playerPlay(player, volume: 0);

    for (var i = 1; i < 100; i++) {
      if (player.state != PlayerState.playing) {
        return;
      }
      var wait = (progressionSeconds * 1000) ~/ 100;

      await Future.delayed(Duration(milliseconds: wait));
      var volume = i / 99;
      await player.setVolume(volume);
    }
  }

  Future<void> playAlarmWithOverrideWithoutProgression(
      AudioPlayer player) async {
    originalVolume = await FlutterVolumeController.getVolume();
    var volumeOverride = AlarmSettings().volumeOverrideValue;

    await FlutterVolumeController.setVolume(volumeOverride / 100);

    return playerPlay(player);
  }

  Future<void> playAlarmWithOverrideWithProgression(AudioPlayer player) async {
    var finalVolume = AlarmSettings().volumeOverrideValue;
    var progressionSeconds = AlarmSettings().volumeProgressionSeconds;

    originalVolume = await FlutterVolumeController.getVolume();

    await FlutterVolumeController.setVolume(0);

    await playerPlay(player);

    for (var i = 1; i < 100; i++) {
      if (player.state != PlayerState.playing) {
        return;
      }
      var wait = (progressionSeconds * 1000) ~/ 100;

      await Future.delayed(Duration(milliseconds: wait));
      var volume = (i / 99) * (finalVolume / 100);
      if (player.state != PlayerState.playing) {
        return;
      }

      await FlutterVolumeController.setVolume(volume);
    }
  }

  void resetOriginalVolume() {
    if (originalVolume != null) {
      FlutterVolumeController.setVolume(originalVolume!);
    }
    originalVolume = null;
  }

  Future<bool> stopTestAlarm() async {
    var stopped = await stopAlarm(testPlayer);
    if (stopped) {
      testAlarmPlaying = false;
    }
    return stopped;
  }

  Future<void> testAlarm() async {
    if (await stopTestAlarm()) {
      return;
    }
    testAlarmPlaying = true;
    // This is to make sure that
    await playAlarm(testPlayer);
  }
}
