import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:carer/change_notifiers/alarms/alarms.dart';
import 'package:carer/change_notifiers/settings/alarm_settings.dart';
import 'package:carer/change_notifiers/settings_cn.dart';
import 'package:carer/change_notifiers/t1d_cn.dart';
import 'package:clock/clock.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_volume_controller/flutter_volume_controller.dart';

const se = SetEquality();

class AlarmsCN extends ChangeNotifier {
  T1DCN t1d;
  SettingsCN settings;
  String get alarmFile {
    return (AlarmSettings.alarmAsset.value as AlarmSounds).asset;
  }

  late final Set<Alarm> allAlarms;

  final Set<Alarm> _triggeredAlarms = <Alarm>{};
  Set<Alarm> get triggeredAlarms => _triggeredAlarms;
  set triggeredAlarms(Set<Alarm> value) {
    if (se.equals(value, _triggeredAlarms)) {
      return;
    }
    _triggeredAlarms.clear();
    _triggeredAlarms.addAll(value);
    notifyListeners();
  }

  final Set<Alarm> _activeAlarms = <Alarm>{};
  Set<Alarm> get activeAlarms => _activeAlarms;
  set activeAlarms(Set<Alarm> value) {
    if (se.equals(value, _activeAlarms)) {
      return;
    }
    _activeAlarms.clear();
    _activeAlarms.addAll(value);
    notifyListeners();
  }

  // Minutes of sleep time
  DateTime _sleepUntil = clock.now();
  DateTime get sleepUntil => _sleepUntil;
  set sleepUntil(DateTime value) {
    _sleepUntil = value;
    notifyListeners();
  }

  bool get notSleeping {
    return sleepDuration.inSeconds <= 0;
  }

  Duration get sleepDuration => _sleepUntil.difference(clock.now());
  set sleepDurationSeconds(int value) {
    _sleepUntil = clock.now().add(Duration(seconds: value));
    notifyListeners();
  }

  final alarmPlayer = AudioPlayer();
  final testPlayer = AudioPlayer();
  final audioContext = const AudioContext(
    android: AudioContextAndroid(),
    iOS: AudioContextIOS(),
  );

  double? originalVolume;

  AlarmsCN({required this.t1d, required this.settings}) {
    allAlarms = {
      UrgentLowAlarm(settings: settings, t1d: t1d),
      LowAlarm(settings: settings, t1d: t1d),
      HighAlarm(settings: settings, t1d: t1d),
      UrgentHighAlarm(settings: settings, t1d: t1d),
      //
      FastDropAlarm(settings: settings, t1d: t1d),
      FastRiseAlarm(settings: settings, t1d: t1d),
      //
      NoDataAlarm(settings: settings, t1d: t1d),
      //
      PredictiveLowAlarm(settings: settings, t1d: t1d),
    };

    Timer.periodic(const Duration(seconds: 1), (Timer t) => checkAlarms());

    settings.addListener(() async {
      checkAlarms();
      await stopTestAlarm();
    });

    t1d.addListener(() {
      checkAlarms();
    });
  }

  void checkAlarms() async {
    var newTriggeredAlarms = <Alarm>{};
    var newActiveAlarms = <Alarm>{};
    var disabledAllAlarms = AlarmSettings.disableAlarms.value;

    for (var alarm in allAlarms) {
      var triggered = await alarm.trigger();
      var active = alarm.active();
      var smartSnooze =
          AlarmSettings.smartSnooze.value && await alarm.smartSnooze();
      // Build the lists

      if (triggered) {
        newTriggeredAlarms.add(alarm);
      }
      // If Sleeping do not add
      if (!disabledAllAlarms &&
          triggered &&
          active &&
          notSleeping &&
          !smartSnooze) {
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

    var override = AlarmSettings.volumeOveride.value;
    var progression = AlarmSettings.volumeProgressionSeconds.value != -1;

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
    int progressionSeconds = AlarmSettings.volumeProgressionSeconds.value;

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
    var volumeOverride = AlarmSettings.volumeOverrideValue.value;

    await FlutterVolumeController.setVolume(volumeOverride / 100);

    return playerPlay(player);
  }

  Future<void> playAlarmWithOverrideWithProgression(AudioPlayer player) async {
    var finalVolume = AlarmSettings.volumeOverrideValue.value;
    var progressionSeconds = AlarmSettings.volumeProgressionSeconds.value;

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
      AlarmSettings.testAlarmPlaying.value = false;
    }
    return stopped;
  }

  Future<void> testAlarm() async {
    if (await stopTestAlarm()) {
      return;
    }

    AlarmSettings.testAlarmPlaying.value = true;
    // This is to make sure that
    await playAlarm(testPlayer);
  }
}
