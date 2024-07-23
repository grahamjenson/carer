import 'package:audioplayers/audioplayers.dart';
import 'package:carer/services/settings/alarm_alert_settings.dart';
import 'package:carer/utils/logs.dart';
import 'package:flutter_volume_controller/flutter_volume_controller.dart';

class AlarmPlayer {
  final alarmAudioPlayer = AudioPlayer();
  final testAudioPlayer = AudioPlayer();

  Future<bool> stopAlarm() async {
    return await stopAudioPlayer(alarmAudioPlayer);
  }

  Future<bool> playAlarm() async {
    // We dont await because this will block until player stops
    playAudioPlayer(alarmAudioPlayer);
    await waitForPlaying(alarmAudioPlayer);

    return true;
  }

  bool alarmPlaying() => alarmAudioPlayer.state == PlayerState.playing;
  bool testAlarmPlaying() => testAudioPlayer.state == PlayerState.playing;

  Future<bool> stopTestAlarm() async {
    return stopAudioPlayer(testAudioPlayer);
  }

  // Return IF playing (regardless if call started to play)
  Future<bool> playTestAlarm() async {
    // We dont await because this will block until player stops
    playAudioPlayer(testAudioPlayer);
    await waitForPlaying(testAudioPlayer);
    return true;
  }

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
    await VolumeProgressionController().resetOriginalVolume();
    alog("stop tries player");
    if (player.state == PlayerState.playing) {
      await player.stop();
      alog("successfully stopped player");
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
    await playerPlay(player, volume: 0);
    VolumeProgressionController().startLoop(player, false);
  }

  final audioContext = const AudioContext(
    android: AudioContextAndroid(),
    iOS: AudioContextIOS(),
  );

  Future<void> playAlarmWithOverrideWithoutProgression(AudioPlayer player) async {
    await VolumeProgressionController().saveOriginalVolume();
    var finalVolume = AlarmAlertSettings().volumeOverrideValue;
    await VolumeProgressionController().setSystemVolume(finalVolume);

    return playerPlay(player);
  }

  Future<void> playAlarmWithOverrideWithProgression(AudioPlayer player) async {
    await playerPlay(player, volume: 0);
    VolumeProgressionController().startLoop(player, true);
  }
}

class VolumeProgressionController {
  //singleton
  static final VolumeProgressionController _instance = VolumeProgressionController._internal();
  factory VolumeProgressionController() => _instance;
  VolumeProgressionController._internal();

  double? _originalVolume;
  bool looping = false;

  // The goal is to have a single volume progression loop at any given time.
  // Because there seems to be pathways where the loop causes bouncing if called multiple times
  Future<void> startLoop(AudioPlayer player, bool systemVolumeOveride) async {
    // TODO: A stupid semafore
    if (looping) {
      return;
    }
    looping = true;

    var finalVolume = AlarmAlertSettings().volumeOverrideValue;
    var progressionSeconds = AlarmAlertSettings().volumeProgressionSeconds;

    if (systemVolumeOveride) {
      await saveOriginalVolume();
      await setSystemVolume(finalVolume);
    }

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

      await player.setVolume(volume);
    }
    looping = false;
  }

  Future<void> setSystemVolume(int volume) async {
    alog("VolumeProgressionController VOLUME = ${volume.toDouble() / 100}");
    await FlutterVolumeController.setVolume(volume.toDouble() / 100);
  }

  Future<void> saveOriginalVolume() async {
    _originalVolume = await FlutterVolumeController.getVolume();
    alog("VolumeProgressionController STORE VOLUME = $_originalVolume");
  }

  Future<void> resetOriginalVolume() async {
    alog("VolumeProgressionController RESET VOLUME? = $_originalVolume");
    if (_originalVolume != null) {
      await FlutterVolumeController.setVolume(_originalVolume!);
    }
    _originalVolume = null;
  }
}
