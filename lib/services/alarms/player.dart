import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:carer/services/settings/alarm_alert_settings.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/utils/logs.dart';
import 'package:flutter_volume_controller/flutter_volume_controller.dart';

abstract class IAlarmPlayer {
  Future<bool> stopAlarm();
  Future<bool> playAlarm();
  bool alarmPlaying();
}

class TestAlarmPlayer implements IAlarmPlayer {
  @override
  Future<bool> stopAlarm() async {
    return true;
  }

  @override
  Future<bool> playAlarm() async {
    return true;
  }

  @override
  bool alarmPlaying() {
    return false;
  }
}

class AlarmPlayer implements IAlarmPlayer {
  final alarmAudioPlayer = AudioPlayer();

  @override
  Future<bool> stopAlarm() async {
    return await stopAudioPlayer(alarmAudioPlayer);
  }

  @override
  Future<bool> playAlarm() async {
    // We dont await because this will block until player stops
    playAudioPlayer(alarmAudioPlayer);
    await waitForPlaying(alarmAudioPlayer);

    return true;
  }

  @override
  bool alarmPlaying() => alarmAudioPlayer.state == PlayerState.playing;

  Future<void> waitForPlaying(AudioPlayer player) async {
    var tries = 0;
    while (player.state != PlayerState.playing && tries < 10) {
      await Future.delayed(const Duration(milliseconds: 100));
      tries++;
    }
    alog("WAITED FOR AUDIO $tries times, and is ${player.state.name}");
  }

  // Return IF stopped
  // Horrific fact that play takes a few seconds, so a play then stop, will result in a play
  Future<bool> stopAudioPlayer(AudioPlayer player) async {
    // This is just to make sure that the player is properly initialized.
    await Future.delayed(const Duration(milliseconds: 300));
    if (player.state == PlayerState.playing) {
      await player.stop();
      player.setVolume(1.0); // Reset volume to default
      alog("successfully stopped player");
      await VolumeProgressionController().resetOriginalVolume();
      return true;
    }
    return false;
  }

  Future<void> playAudioPlayer(AudioPlayer player) async {
    if (player.state == PlayerState.playing) {
      return;
    }

    var override = AlarmAlertSettings().volumeOveride;
    var progression = AlarmAlertSettings().volumeProgressionSeconds != -1;

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

  String get alarmFile {
    return (AlarmAlertSettings().alarmAsset).asset;
  }

  Future<void> playerPlay(AudioPlayer player, double? volume) {
    return player.play(AssetSource(alarmFile), volume: volume).catchError((err) {
      // Swallow the error here
      print("Error playing alarm: $err");
      alog("Error playing alarm: $err");
      return;
    });
  }

  Future<void> playAlarmWithoutOverrideWithoutProgression(AudioPlayer player) async {
    return playerPlay(player, null);
  }

  Future<void> playAlarmWithoutOverrideWithProgression(AudioPlayer player) async {
    await playerPlay(player, 0);
    // progression
    VolumeProgressionController().startLoop(player);
  }

  Future<void> playAlarmWithOverrideWithoutProgression(AudioPlayer player) async {
    // Override
    await VolumeProgressionController().saveOriginalVolume();
    var finalVolume = AlarmAlertSettings().volumeOverrideValue;
    await VolumeProgressionController().setSystemVolume(finalVolume);

    return playerPlay(player, null);
  }

  Future<void> playAlarmWithOverrideWithProgression(AudioPlayer player) async {
    // Override
    await VolumeProgressionController().saveOriginalVolume();
    var finalVolume = AlarmAlertSettings().volumeOverrideValue;
    await VolumeProgressionController().setSystemVolume(finalVolume);

    await playerPlay(player, 0);

    // progression
    VolumeProgressionController().startLoop(player);
  }
}

class VolumeProgressionController {
  //singleton
  static final VolumeProgressionController _instance = VolumeProgressionController._internal();
  factory VolumeProgressionController() => _instance;
  VolumeProgressionController._internal();

  double? _originalVolume;
  Map<AudioPlayer, bool> loopingMap = {};

  // The goal is to have a single volume progression loop per player at any given time.
  // Because there seems to be pathways where the loop causes bouncing if called multiple times
  Future<void> startLoop(AudioPlayer player) async {
    // Lock
    if (!loopingMap.containsKey(player)) {
      loopingMap[player] = false;
    }

    if (loopingMap[player]!) {
      return;
    }
    loopingMap[player] = true;

    var progressionSeconds = AlarmAlertSettings().volumeProgressionSeconds;

    for (var i = 1; i < 100; i++) {
      if (player.state != PlayerState.playing) {
        break;
      }
      var wait = (progressionSeconds * 1000) ~/ 100;

      await Future.delayed(Duration(milliseconds: wait));
      var volume = (i / 99);
      if (player.state != PlayerState.playing) {
        break;
      }
      double percievedVolume = pow(volume, 2).toDouble();

      await player.setVolume(percievedVolume);
    }

    loopingMap[player] = false;
  }

  Future<void> setSystemVolume(int volume) async {
    alog("VolumeProgressionController VOLUME = ${volume.toDouble() / 100}");
    await FlutterVolumeController.setVolume(volume.toDouble() / 100);
  }

  Future<void> saveOriginalVolume() async {
    var (oV, err) = await go(FlutterVolumeController.getVolume());
    if (oV != null) {
      _originalVolume = oV;
      alog("VolumeProgressionController STORE VOLUME = $_originalVolume");
    } else {
      _originalVolume = null;
      alog("VolumeProgressionController ERROR SAVING VOLUME = $err");
    }
  }

  Future<void> resetOriginalVolume() async {
    if (_originalVolume != null) {
      var (_, err) = await go(FlutterVolumeController.setVolume(_originalVolume!));
      if (err != null) {
        alog("VolumeProgressionController ERROR SETTING VOLUME = $err");
      } else {
        alog("VolumeProgressionController RESET VOLUME? = $_originalVolume");
      }
    }
    _originalVolume = null;
  }
}
