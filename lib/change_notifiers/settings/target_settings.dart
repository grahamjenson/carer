import 'package:carer/change_notifiers/settings_cn.dart';
import 'package:carer/sql/key_value_store.dart';
import 'package:signals/signals.dart';

// find where in the target range and by what proportion a number is
// returns a tuple of (Targets, proportion)

enum TargetSettings {
  targetHigh,
  targetLow,
  urgentHigh,
  urgentLow;

  Signal get _signal {
    return _settingsSignals[this]!;
  }

  set value(int value) {
    var clone = {
      TargetSettings.targetHigh.name: TargetSettings.targetHigh.value,
      TargetSettings.targetLow.name: TargetSettings.targetLow.value,
      TargetSettings.urgentHigh.name: TargetSettings.urgentHigh.value,
      TargetSettings.urgentLow.name: TargetSettings.urgentLow.value,
    };

    // Override the propesed setting
    clone[name] = value;
    if (!validTargets(
        clone[TargetSettings.urgentLow.name]!,
        clone[TargetSettings.targetLow.name]!,
        clone[TargetSettings.targetHigh.name]!,
        clone[TargetSettings.urgentHigh.name]!)) {
      return;
    }

    _settingsSignals[this]!.value = value;
  }

  int get peek {
    return _settingsSignals[this]!.peek();
  }

  int get value {
    return _settingsSignals[this]!.value;
  }

  bool validTargets(
      int urgentLow, int targetLow, int targetHigh, int urgentHigh) {
    return 9 <= urgentLow &&
        urgentLow <= targetLow &&
        targetLow <= targetHigh &&
        targetHigh <= urgentHigh &&
        urgentHigh <= 360;
  }
}

Map<TargetSettings, Signal<int>> _settingsSignals = {};

class TargetSettingsCN {
  KeyValueStore prefs;
  SettingsCN settings;

  TargetSettingsCN({required this.prefs, required this.settings}) {
    _settingsSignals = {
      TargetSettings.targetHigh: Signal<int>(
          prefs.getInt(TargetSettings.targetHigh.name, defaultValue: 180)!),
      TargetSettings.targetLow: Signal<int>(
          prefs.getInt(TargetSettings.targetLow.name, defaultValue: 72)!),
      TargetSettings.urgentHigh: Signal<int>(
          prefs.getInt(TargetSettings.urgentHigh.name, defaultValue: 270)!),
      TargetSettings.urgentLow: Signal<int>(
          prefs.getInt(TargetSettings.urgentLow.name, defaultValue: 55)!),
    };

    effect(() => prefs.setInt(
        TargetSettings.targetHigh.name, TargetSettings.targetHigh.value));

    effect(() => prefs.setInt(
        TargetSettings.targetLow.name, TargetSettings.targetLow.value));

    effect(() => prefs.setInt(
        TargetSettings.urgentHigh.name, TargetSettings.urgentHigh.value));

    effect(() => prefs.setInt(
        TargetSettings.urgentLow.name, TargetSettings.urgentLow.value));
  }
}
