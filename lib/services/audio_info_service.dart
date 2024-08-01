import 'dart:io';

import 'package:carer/services/timer_service.dart';
import 'package:carer/utils/futures.dart';
import 'package:signals/signals_flutter.dart';
import 'package:sound_mode/sound_mode.dart';
import 'package:sound_mode/utils/ringer_mode_statuses.dart';

class AudioInfoService {
  static final AudioInfoService _instance = AudioInfoService._();
  factory AudioInfoService() {
    return _instance;
  }

  AudioInfoService._() {
    signalAssign(
      ringerMode,
      getRingerMode,
      debugLabel: "RingerModeSignal",
      dependencies: [TimerService().fiveSecondSignal],
    );
  }

  Signal<RingerMode> ringerMode = Signal(RingerMode.unknown, debugLabel: "RingerMode");

  Future<RingerMode> getRingerMode() async {
    RingerMode ringerStatus = RingerMode.unknown;
    if (!Platform.isIOS) {
      return RingerMode.unknown;
    }

    try {
      var ringerModeStatus = await SoundMode.ringerModeStatus;
      switch (ringerModeStatus) {
        case RingerModeStatus.normal:
          ringerStatus = RingerMode.normal;
          break;
        case RingerModeStatus.silent:
          ringerStatus = RingerMode.silent;
          break;
        case RingerModeStatus.vibrate:
          ringerStatus = RingerMode.vibrate;
          break;
        default:
          ringerStatus = RingerMode.unknown;
          break;
      }
    } catch (err) {
      ringerStatus = RingerMode.unknown;
    }

    return ringerStatus;
  }
}

enum RingerMode { unknown, normal, silent, vibrate }
