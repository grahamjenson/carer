import 'dart:io';

import 'package:battery_plus/battery_plus.dart';
import 'package:carer/services/timer_service.dart';
import 'package:carer/utils/futures.dart';
import 'package:signals/signals_flutter.dart';
import 'package:sound_mode/sound_mode.dart';
import 'package:sound_mode/utils/ringer_mode_statuses.dart';

class PlatformInfoService {
  static final PlatformInfoService _instance = PlatformInfoService._();
  factory PlatformInfoService() {
    return _instance;
  }

  PlatformInfoService._() {
    signalAssign(
      ringerMode,
      getRingerMode,
      debugLabel: "RingerModeSignal",
      dependencies: [TimerService().fiveSecondSignal],
    );

    var battery = Battery();
    battery.onBatteryStateChanged.listen((BatteryState state) {
      switch (state) {
        case BatteryState.full:
          batteryMode.value = BatteryMode.full;
          break;
        case BatteryState.charging:
          batteryMode.value = BatteryMode.charging;
          break;
        case BatteryState.connectedNotCharging:
          batteryMode.value = BatteryMode.connectedNotCharging;
          break;
        case BatteryState.discharging:
          batteryMode.value = BatteryMode.discharging;
          break;
        case BatteryState.unknown:
          batteryMode.value = BatteryMode.unknown;
          break;
      }
    });
  }

  Signal<RingerMode> ringerMode = Signal(RingerMode.unknown, debugLabel: "RingerMode");
  Signal<BatteryMode> batteryMode = Signal(BatteryMode.unknown, debugLabel: "BatteryMode");

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

enum BatteryMode { full, charging, connectedNotCharging, discharging, unknown }
