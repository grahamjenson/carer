import 'package:carer/change_notifiers/settings/alarm_settings.dart';
import 'package:carer/change_notifiers/settings_cn.dart';
import 'package:carer/change_notifiers/t1d_cn.dart';
import 'package:carer/models/sgv.dart';
import 'package:carer/predictors/sgv_predictors.dart';
import 'package:carer/utils/math.dart';

Future<Range5> atPredictedTime(int mins, SettingsCN settings) async {
  Exp2Predictor exp2predictor = Exp2Predictor();
  await exp2predictor.init();
  var sgvAtTime = exp2predictor.predictMin(mins);
  var (range, _) = targetRange(sgvAtTime.value.toInt());
  return range;
}

abstract class Alarm {
  final SettingsCN settings;

  final T1DCN t1d;

  const Alarm({required this.settings, required this.t1d});

  String get name;
  String get description;

  Future<bool> trigger();
  bool active();
  Future<bool> smartSnooze() async {
    return false;
  }
}

class PredictiveLowAlarm extends Alarm {
  const PredictiveLowAlarm({required super.settings, required super.t1d});

  @override
  String get name => 'PredictiveLowAlarm Low Alarm';

  @override
  String get description =>
      'Triggers when it predicts a low in ${AlarmSettings.lowPredictionMinutes.value}m';

  @override
  Future<bool> trigger() async {
    var range = await atPredictedTime(
        AlarmSettings.lowPredictionMinutes.value, settings);
    return range == Range5.veryLow || range == Range5.low;
  }

  @override
  bool active() {
    return AlarmSettings.lowPredictionAlarm.value;
  }
}

class UrgentLowAlarm extends Alarm {
  const UrgentLowAlarm({required super.settings, required super.t1d});

  @override
  String get name => 'Urgent Low Alarm';

  @override
  String get description => 'Triggers when BGL is below the urgent low target';

  @override
  Future<bool> trigger() async {
    return t1d.targetRange5 == Range5.veryLow;
  }

  @override
  bool active() {
    return AlarmSettings.urgentLowAlarm.value;
  }
}

class LowAlarm extends Alarm {
  const LowAlarm({required super.settings, required super.t1d});

  @override
  String get name => 'Low Alarm ${AlarmSettings.lowMinutes.value}m';

  @override
  String get description =>
      'Triggers when all BGLs for a time period are below the low target';

  @override
  Future<bool> trigger() async {
    var latest =
        t1d.targetRange5 == Range5.low || t1d.targetRange5 == Range5.veryLow;
    if (!latest) {
      return false;
    }
    List<Range5> targets =
        await t1d.targetRange5ForMins(AlarmSettings.lowMinutes.value);
    if (targets.isEmpty) {
      return true;
    }
    return targets.every((e) => e == Range5.low || e == Range5.veryLow);
  }

  @override
  bool active() {
    return AlarmSettings.lowAlarm.value;
  }

  @override
  Future<bool> smartSnooze() async {
    var range = await atPredictedTime(10, settings);

    return range == Range5.mid;
  }
}

class HighAlarm extends Alarm {
  const HighAlarm({required super.settings, required super.t1d});

  @override
  String get name => 'High Alarm ${AlarmSettings.highMinutes.value}m';

  @override
  String get description =>
      'Triggers when all BGLs for a time period are above the high target';

  @override
  Future<bool> trigger() async {
    var latest =
        t1d.targetRange5 == Range5.high || t1d.targetRange5 == Range5.veryHigh;
    if (!latest) {
      return false;
    }
    List<Range5> targets =
        await t1d.targetRange5ForMins(AlarmSettings.highMinutes.value);
    if (targets.isEmpty) {
      return true;
    }
    return targets.every((e) => e == Range5.high || e == Range5.veryHigh);
  }

  @override
  bool active() {
    return AlarmSettings.highAlarm.value;
  }

  @override
  Future<bool> smartSnooze() async {
    var range = await atPredictedTime(10, settings);
    return range == Range5.mid;
  }
}

class UrgentHighAlarm extends Alarm {
  const UrgentHighAlarm({required super.settings, required super.t1d});

  @override
  String get name => 'Urgent High Alarm';

  @override
  String get description => 'Triggers when BGL is above the urgent high target';

  @override
  Future<bool> trigger() async {
    return t1d.targetRange5 == Range5.veryHigh;
  }

  @override
  bool active() {
    return AlarmSettings.urgentHighAlarm.value;
  }
}

class FastRiseAlarm extends Alarm {
  const FastRiseAlarm({required super.settings, required super.t1d});

  @override
  String get name =>
      'Fast Rise Alarm ${AlarmSettings.fastRiseAlarmMinutes.value}';

  @override
  String get description => 'Triggers when BGL is rising quickly';

  @override
  Future<bool> trigger() async {
    // Dont trigger if High or Very High, fast drop when high is what we want
    if (t1d.targetRange5 == Range5.low || t1d.targetRange5 == Range5.veryLow) {
      return false;
    }

    // Get the diffs for the last n minutes and make sure they are all above the set delta
    var diffs =
        await t1d.diffPer5Minute(AlarmSettings.fastRiseAlarmMinutes.value);
    if (diffs.isEmpty) {
      return false;
    }
    if (diffs.every((element) => element > AlarmSettings.fastRiseDelta.value)) {
      return true;
    }
    return false;
  }

  @override
  bool active() {
    return AlarmSettings.fastRiseAlarm.value;
  }
}

class FastDropAlarm extends Alarm {
  const FastDropAlarm({required super.settings, required super.t1d});

  @override
  String get name =>
      'Fast Drop Alarm ${AlarmSettings.fastDropAlarmMinutes.value}';

  @override
  String get description => 'Triggers when BGL is dropping quickly';

  @override
  Future<bool> trigger() async {
    // Dont trigger if High or Very High, fast drop when high is what we want
    if (t1d.targetRange5 == Range5.high ||
        t1d.targetRange5 == Range5.veryHigh) {
      return false;
    }

    // Get the diffs for the last n minutes and make sure they are all below the set delta
    var diffs =
        await t1d.diffPer5Minute(AlarmSettings.fastDropAlarmMinutes.value);
    if (diffs.isEmpty) {
      return false;
    }

    if (diffs.every((element) => element < AlarmSettings.fastDropDelta.value)) {
      return true;
    }
    return false;
  }

  @override
  bool active() {
    return AlarmSettings.fastDropAlarm.value;
  }
}

class NoDataAlarm extends Alarm {
  const NoDataAlarm({required super.settings, required super.t1d});

  @override
  String get name => 'No Data Alarm ${AlarmSettings.noDataAlarmMinutes.value}';

  @override
  String get description => 'Triggers when no data is received';

  // This allows the alarm to still trigger with "default" even when not active
  int alarmMinutes() {
    var mins = AlarmSettings.noDataAlarmMinutes.value;
    if (mins == -1) {
      mins = 20;
    }
    return mins;
  }

  @override
  Future<bool> trigger() async {
    if (AlarmSettings.noDataAlarmMinutes.value == -1) {
      return false;
    }
    var lastSGV = await SGV.lastSGV();
    if (lastSGV == null) {
      return false;
    }

    return lastSGV.age.inMinutes > alarmMinutes();
  }

  @override
  bool active() {
    return AlarmSettings.noDataAlarmMinutes.value != -1;
  }
}
