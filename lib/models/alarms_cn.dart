import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:carer/models/alarms/alarms.dart';
import 'package:carer/models/settings_cn.dart';
import 'package:carer/models/t1d_cn.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_volume_controller/flutter_volume_controller.dart';

const se = SetEquality();

class AlarmsCN extends ChangeNotifier {
  T1DCN t1d;
  Settings settings;

  static const String alarmFile = "alarm.mp3";

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
  DateTime _sleepUntil = DateTime.now();
  DateTime get sleepUntil => _sleepUntil;
  set sleepUntil(DateTime value) {
    _sleepUntil = value;
    notifyListeners();
  }

  bool get sleeping {
    return sleepDuration.inSeconds <= 0;
  }

  Duration get sleepDuration => _sleepUntil.difference(DateTime.now());
  set sleepDurationSeconds(int value) {
    _sleepUntil = DateTime.now().add(Duration(seconds: value));
    notifyListeners();
  }

  final alarmPlayer = AudioPlayer();
  final List<AudioPlayer> testPlayers = [];
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
    };

    Timer.periodic(const Duration(seconds: 1), (Timer t) => checkAlarms());

    settings.addListener(() async {
      checkAlarms();
      await stopAllTestAlarms();
    });

    t1d.addListener(() {
      checkAlarms();
    });
  }

  void checkAlarms() {
    var newTriggeredAlarms = <Alarm>{};
    var newActiveAlarms = <Alarm>{};

    for (var alarm in allAlarms) {
      var triggered = alarm.trigger();
      var active = alarm.active();
      // Build the lists

      if (triggered) {
        newTriggeredAlarms.add(alarm);
      }
      // If Sleeping do not add
      if (triggered && active && sleeping) {
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

  void stopAlarm(AudioPlayer player) {
    if (player.state == PlayerState.playing) {
      player.stop();
      resetOriginalVolume();
    }
  }

  Future<void> playAlarm(AudioPlayer player) async {
    if (player.state == PlayerState.playing) {
      return;
    }

    var override = settings.alarmSettings.volumeOveride;
    var progression = settings.alarmSettings.volumeProgressionSeconds != -1;
    var progressionMinutes = settings.alarmSettings.volumeProgressionSeconds;
    var finalVolume = settings.alarmSettings.volumeOverrideValue;

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

  Future<void> playAlarmWithoutOverrideWithoutProgression(
      AudioPlayer player) async {
    return player.play(AssetSource(alarmFile));
  }

  Future<void> playAlarmWithoutOverrideWithProgression(
      AudioPlayer player) async {
    var progressionSeconds = settings.alarmSettings.volumeProgressionSeconds;

    await player.play(AssetSource(alarmFile), volume: 0);

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
    var volumeOverride = settings.alarmSettings.volumeOverrideValue;

    await FlutterVolumeController.setVolume(volumeOverride / 100);

    return player.play(AssetSource(alarmFile));
  }

  Future<void> playAlarmWithOverrideWithProgression(AudioPlayer player) async {
    var finalVolume = settings.alarmSettings.volumeOverrideValue;
    var progressionSeconds = settings.alarmSettings.volumeProgressionSeconds;

    originalVolume = await FlutterVolumeController.getVolume();

    await FlutterVolumeController.setVolume(0);

    await player.play(AssetSource(alarmFile));

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

  bool stopAllTestAlarmsNow = false;
  Future<bool> stopAllTestAlarms() async {
    if (stopAllTestAlarmsNow) {
      return false; // A stupid way of forcing this method to be only called once concurrently
    }
    stopAllTestAlarmsNow = true;
    if (testPlayers.isNotEmpty) {
      for (var element in testPlayers) {
        await element.stop();
      }
      testPlayers.clear();
      resetOriginalVolume();
      settings.alarmSettings.testAlarmPlaying = false;
      stopAllTestAlarmsNow = false;
      return true;
    }
    stopAllTestAlarmsNow = false;
    return false;
  }

  Future<void> testAlarm() async {
    if (await stopAllTestAlarms()) {
      return;
    }

    settings.alarmSettings.testAlarmPlaying = true;
    // This is to make sure that
    var tp = AudioPlayer();
    testPlayers.add(tp);
    await playAlarm(tp);
    await Future.delayed(
        const Duration(seconds: 60)); // set a max limit so at least they die
    stopAllTestAlarms();
  }
}
