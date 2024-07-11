import 'package:audioplayers/audioplayers.dart';
import 'package:carer/services/settings/alarm_alert_settings.dart';
import 'package:flutter_volume_controller/flutter_volume_controller.dart';

class AlarmPlayer {
  double? originalVolume;

  final alarmAudioPlayer = AudioPlayer();
  final testAudioPlayer = AudioPlayer();

  Future<bool> stopAlarm() async {
    return await stopAudioPlayer(alarmAudioPlayer);
  }

  Future<bool> playAlarm() async {
    // We dont await because this will block until player stops
    playAudioPlayer(alarmAudioPlayer);
    return true;
  }

  bool alarmPlaying() => alarmAudioPlayer.state == PlayerState.playing;
  bool testAlarmPlaying() => testAudioPlayer.state == PlayerState.playing;

  Future<bool> stopTestAlarm() async {
    return stopAudioPlayer(testAudioPlayer);
  }

  // Return IF playing (regardless if call started to play)
  Future<bool> playTestAlarm() async {
    // Dont start playing if already playing instead stop
    if (testAlarmPlaying()) {
      await stopTestAlarm();
      return false;
    }
    // We dont await because this will block until player stops
    playAudioPlayer(testAudioPlayer);
    return true;
  }

  // Return IF stopped
  Future<bool> stopAudioPlayer(AudioPlayer player) async {
    if (player.state == PlayerState.playing) {
      await player.stop();
      resetOriginalVolume();
      return true;
    }
    return true;
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

  Future<void> playerPlay(AudioPlayer player, {double? volume}) {
    return player.play(
      AssetSource(alarmFile),
      ctx: audioContext,
      volume: volume,
    );
  }

  Future<void> playAlarmWithoutOverrideWithoutProgression(AudioPlayer player) async {
    return playerPlay(player);
  }

  Future<void> playAlarmWithoutOverrideWithProgression(AudioPlayer player) async {
    int progressionSeconds = AlarmAlertSettings().volumeProgressionSeconds;

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

  final audioContext = const AudioContext(
    android: AudioContextAndroid(),
    iOS: AudioContextIOS(),
  );

  Future<void> playAlarmWithOverrideWithoutProgression(AudioPlayer player) async {
    originalVolume = await FlutterVolumeController.getVolume();
    var volumeOverride = AlarmAlertSettings().volumeOverrideValue;

    await FlutterVolumeController.setVolume(volumeOverride / 100);

    return playerPlay(player);
  }

  Future<void> playAlarmWithOverrideWithProgression(AudioPlayer player) async {
    var finalVolume = AlarmAlertSettings().volumeOverrideValue;
    var progressionSeconds = AlarmAlertSettings().volumeProgressionSeconds;

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
}
