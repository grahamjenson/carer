import 'package:carer/models/settings_cn.dart';
import 'package:carer/sql/key_value_store.dart';

// find where in the target range and by what proportion a number is
// returns a tuple of (Targets, proportion)

enum TargetSettingNames {
  targetHigh,
  targetLow,
  urgentHigh,
  urgentLow,
}

class TargetSettings {
  KeyValueStore prefs;
  Settings settings;

  TargetSettings({required this.prefs, required this.settings});

  // getters
  int get targetHigh {
    return prefs.getInt(TargetSettingNames.targetHigh.name, defaultValue: 180)!;
  }

  int get targetLow {
    return prefs.getInt(TargetSettingNames.targetLow.name, defaultValue: 72)!;
  }

  int get urgentHigh {
    return prefs.getInt(TargetSettingNames.urgentHigh.name, defaultValue: 270)!;
  }

  int get urgentLow {
    return prefs.getInt(TargetSettingNames.urgentLow.name, defaultValue: 55)!;
  }

  // setters

  set targetHigh(int value) {
    setTarget(TargetSettingNames.targetHigh, value);
  }

  set targetLow(int value) {
    setTarget(TargetSettingNames.targetLow, value);
  }

  set urgentHigh(int value) {
    setTarget(TargetSettingNames.urgentHigh, value);
  }

  set urgentLow(int value) {
    setTarget(TargetSettingNames.urgentLow, value);
  }

  bool validTargets(
      int urgentLow, int targetLow, int targetHigh, int urgentHigh) {
    return 9 <= urgentLow &&
        urgentLow <= targetLow &&
        targetLow <= targetHigh &&
        targetHigh <= urgentHigh &&
        urgentHigh <= 360;
  }

  Future<void> setTarget(TargetSettingNames setting, int value) async {
    var clone = {
      TargetSettingNames.targetHigh.name: targetHigh,
      TargetSettingNames.targetLow.name: targetLow,
      TargetSettingNames.urgentHigh.name: urgentHigh,
      TargetSettingNames.urgentLow.name: urgentLow,
    };
    // Override the propesed setting
    clone[setting.name] = value;
    if (!validTargets(
        clone[TargetSettingNames.urgentLow.name]!,
        clone[TargetSettingNames.targetLow.name]!,
        clone[TargetSettingNames.targetHigh.name]!,
        clone[TargetSettingNames.urgentHigh.name]!)) {
      return;
    }

    await prefs.setInt(setting.name, value);
    settings.notify();
  }
}
