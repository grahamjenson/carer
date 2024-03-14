import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:carer/models/settings_cn.dart';
import 'package:carer/models/t1d_cn.dart';
import 'package:carer/utils/math.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_volume_controller/flutter_volume_controller.dart';

enum Alarms {
  targetVeryLow,
  targetLow,
  targetHigh,
  targetVeryHigh,

  diffVeryLow,
  diffVeryHigh,
}

const se = SetEquality();

class AlarmsCN extends ChangeNotifier {
  T1DCN t1d;
  Settings settings;

  static const String alarmFile = "alarm.mp3";

  final Set<Alarms> _triggeredAlarms = <Alarms>{};
  Set<Alarms> get triggeredAlarms => _triggeredAlarms;
  set triggeredAlarms(Set<Alarms> value) {
    if (se.equals(value, _triggeredAlarms)) {
      return;
    }
    _triggeredAlarms.clear();
    _triggeredAlarms.addAll(value);
    notifyListeners();
  }

  final Set<Alarms> _alarms = <Alarms>{};
  Set<Alarms> get alarms => _alarms;
  set alarms(Set<Alarms> value) {
    if (se.equals(value, _alarms)) {
      return;
    }
    _alarms.clear();
    _alarms.addAll(value);
    notifyListeners();
  }

  // Minutes of sleep time
  DateTime _sleepUntil = DateTime.now();
  DateTime get sleepUntil => _sleepUntil;
  set sleepUntil(DateTime value) {
    _sleepUntil = value;
    notifyListeners();
  }

  Duration get sleepDuration => _sleepUntil.difference(DateTime.now());
  set sleepDurationSeconds(int value) {
    _sleepUntil = DateTime.now().add(Duration(seconds: value));
    notifyListeners();
  }

  final alarmPlayer = AudioPlayer();
  final testplayer = AudioPlayer();

  AlarmsCN({required this.t1d, required this.settings}) {
    Timer.periodic(const Duration(seconds: 1), (Timer t) => checkAlarms());

    settings.addListener(() {
      checkAlarms();
    });

    t1d.addListener(() {
      checkAlarms();
    });
  }

  void checkAlarms() {
    var newAlarms = <Alarms>{};

    switch (t1d.targetRange5) {
      case Range5.veryLow:
        newAlarms.add(Alarms.targetVeryLow);
        break;
      case Range5.low:
        newAlarms.add(Alarms.targetLow);
        break;
      case Range5.high:
        newAlarms.add(Alarms.targetHigh);
        break;
      case Range5.veryHigh:
        newAlarms.add(Alarms.targetVeryHigh);
        break;
      default:
        break;
    }

    switch (t1d.diffRange7) {
      case Range7.veryVeryLow:
        newAlarms.add(Alarms.diffVeryLow);
        break;
      case Range7.veryLow:
        newAlarms.add(Alarms.diffVeryLow);
        break;
      case Range7.veryHigh:
        newAlarms.add(Alarms.diffVeryHigh);
        break;
      case Range7.veryVeryHigh:
        newAlarms.add(Alarms.diffVeryHigh);
        break;
      default:
        break;
    }

    // Set alarms that have been triggered
    triggeredAlarms = newAlarms;

    alarms = filterAlarms(newAlarms);

    // Set alarms

    if (alarms.isEmpty) {
      stopAlarm(alarmPlayer);
    } else {
      playAlarm(alarmPlayer);
    }
  }

  void stopAlarm(AudioPlayer player) {
    if (player.state == PlayerState.playing) {
      player.stop();
    }
  }

  Future<void> playAlarm(AudioPlayer player) async {
    if (player.state == PlayerState.playing) {
      return;
    }

    var override = settings.alarmSettings.volumeOveride;
    var progression = settings.alarmSettings.volumeProgressionMinutes != -1;
    var progressionMinutes = settings.alarmSettings.volumeProgressionMinutes;
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
    var progression = 0.1;

    return player
        .play(AssetSource(alarmFile), volume: progression)
        .then((v) => Future.delayed(const Duration(seconds: 5)))
        .then((v) => player.setVolume(0.5))
        .then((v) => Future.delayed(const Duration(seconds: 5)))
        .then((v) => player.setVolume(1));
  }

  Future<void> playAlarmWithOverrideWithoutProgression(
      AudioPlayer player) async {
    await FlutterVolumeController.setVolume(
        settings.alarmSettings.volumeOverrideValue / 100);

    return player.play(AssetSource(alarmFile));
  }

  Future<void> playAlarmWithOverrideWithProgression(AudioPlayer player) async {
    await FlutterVolumeController.setVolume(
        0.3 * settings.alarmSettings.volumeOverrideValue / 100);

    return player
        .play(AssetSource(alarmFile))
        .then((v) => Future.delayed(const Duration(seconds: 5)))
        .then((v) => FlutterVolumeController.setVolume(
            0.5 * settings.alarmSettings.volumeOverrideValue / 100))
        .then((v) => Future.delayed(const Duration(seconds: 5)))
        .then((v) => FlutterVolumeController.setVolume(
            settings.alarmSettings.volumeOverrideValue / 100));
  }

  Future<void> testAlarm() async {
    if (testplayer.state == PlayerState.playing) {
      return stopAlarm(testplayer);
    }

    return playAlarm(testplayer).then((value) {
      return Future.delayed(const Duration(seconds: 60));
    }).then((v) {
      return stopAlarm(testplayer);
    });
  }

  Set<Alarms> filterAlarms(Set<Alarms> alarms) {
    if (sleepDuration.inSeconds > 0) {
      // We are sleeping, no alarms right now
      alarms.clear();
      return alarms;
    }

    if (!settings.alarmSettings.highAlarm) {
      alarms.remove(Alarms.targetHigh);
      alarms.remove(Alarms.targetVeryHigh);
    }

    if (!settings.alarmSettings.lowAlarm) {
      alarms.remove(Alarms.targetLow);
      alarms.remove(Alarms.targetVeryLow);
    }

    if (!settings.alarmSettings.fastRiseAlarm) {
      alarms.remove(Alarms.diffVeryHigh);
    }

    if (!settings.alarmSettings.fastDropAlarm) {
      alarms.remove(Alarms.diffVeryLow);
    }
    return alarms;
  }
}
