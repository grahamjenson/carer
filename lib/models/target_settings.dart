import 'package:carer/models/settings_cn.dart';
import 'package:carer/widgets/math.dart';
import 'package:shared_preferences/shared_preferences.dart';

// find where in the target range and by what proportion a number is
// returns a tuple of (Targets, proportion)

enum TargetSettingNames {
  targetHigh,
  targetLow,
  urgentHigh,
  urgentLow,
}

class TargetSettings {
  SharedPreferences prefs;
  Settings settings;

  TargetSettings({required this.prefs, required this.settings});

  Map<String, int> targets = {
    TargetSettingNames.targetHigh.name: 180,
    TargetSettingNames.targetLow.name: 72,
    TargetSettingNames.urgentHigh.name: 270,
    TargetSettingNames.urgentLow.name: 55
  };

  void populate() {
    for (var setting in targets.entries) {
      var value = prefs.getInt(setting.key);
      if (value != null) {
        targets[setting.key] = value;
      }
    }
  }

  // getters
  int get targetHigh {
    return targets[TargetSettingNames.targetHigh.name]!;
  }

  int get targetLow {
    return targets[TargetSettingNames.targetLow.name]!;
  }

  int get urgentHigh {
    return targets[TargetSettingNames.urgentHigh.name]!;
  }

  int get urgentLow {
    return targets[TargetSettingNames.urgentLow.name]!;
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
    var clone = Map<String, int>.from(targets);
    clone[setting.name] = value;
    if (validTargets(
        clone[TargetSettingNames.urgentLow.name]!,
        clone[TargetSettingNames.targetLow.name]!,
        clone[TargetSettingNames.targetHigh.name]!,
        clone[TargetSettingNames.urgentHigh.name]!)) {
      targets = clone;
    } else {
      return;
    }
    await prefs.setInt(setting.name, value);
    settings.notifyListeners();
  }

  (Range, double) targetRange(int sgv) {
    var low = settings.targetLow.toDouble();
    var high = settings.targetHigh.toDouble();
    var veryHigh = settings.urgentHigh.toDouble();
    var veryLow = settings.urgentLow.toDouble();

    return range(veryLow, low, high, veryHigh, sgv.toDouble());
  }
}
