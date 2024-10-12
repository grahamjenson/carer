import 'dart:io';

import 'package:battery_plus/battery_plus.dart';
import 'package:carer/services/timer_service.dart';
import 'package:carer/utils/futures.dart';
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

    signalAssign(batteryLevel, () => battery.batteryLevel, debugLabel: "BatteryLevelSignal", dependencies: [TimerService().fiveSecondSignal]);

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

  ASignal<RingerMode> ringerMode = ASignal(RingerMode.unknown, debugLabel: "RingerMode");
  ASignal<BatteryMode> batteryMode = ASignal(BatteryMode.unknown, debugLabel: "BatteryMode");
  ASignal<int> batteryLevel = ASignal(100, debugLabel: "BatteryLevel");

  bool thisPhoneIsCharging() {
    return batteryMode.value == BatteryMode.charging ||
        batteryMode.value == BatteryMode.connectedNotCharging ||
        batteryMode.value == BatteryMode.full;
  }

  int thisPhonesBatteryLevel() {
    return batteryLevel.value;
  }

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
