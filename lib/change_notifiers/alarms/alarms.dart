import 'package:carer/change_notifiers/settings/alarm_settings.dart';
import 'package:carer/change_notifiers/settings_cn.dart';
import 'package:carer/change_notifiers/t1d_cn.dart';
import 'package:carer/models/models.dart';
import 'package:carer/utils/math.dart';

abstract class Alarm {
  final SettingsCN settings;
  AlarmSettings get alarmSettings => settings.alarmSettings;
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
      'Triggers when it predicts a low in ${alarmSettings.lowPredictionMinutes}m';

  @override
  Future<bool> trigger() async {
    var lastSGV = await SGVs.lastSGV();
    if (lastSGV == null) {
      return false;
    }
    var diffs = await t1d.diffPer5Minute(15);
    if (diffs.isEmpty) {
      return false;
    }

    var meanDiff = mean(diffs);
    var meanDiffPerMinute = meanDiff / 5;
    var predictedDiff = meanDiffPerMinute * alarmSettings.lowPredictionMinutes;
    var predictedSGV = (lastSGV.value + predictedDiff).round();

    var (range, _) = targetRange(settings, predictedSGV);
    return range == Range5.veryLow || range == Range5.low;
  }

  @override
  bool active() {
    return alarmSettings.lowPredictionAlarm;
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
    return alarmSettings.urgentLowAlarm;
  }
}

class LowAlarm extends Alarm {
  const LowAlarm({required super.settings, required super.t1d});

  @override
  String get name => 'Low Alarm ${alarmSettings.lowMinutes}m';

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
        await t1d.targetRange5ForMins(alarmSettings.lowMinutes);
    if (targets.isEmpty) {
      return true;
    }
    return targets.every((e) => e == Range5.low || e == Range5.veryLow);
  }

  @override
  bool active() {
    return alarmSettings.lowAlarm;
  }

  @override
  Future<bool> smartSnooze() async {
    var diffs = await t1d.diffPer5Minute(10);
    if (diffs.isEmpty) {
      return false;
    }

    return diffs.last > 0;
  }
}

class HighAlarm extends Alarm {
  const HighAlarm({required super.settings, required super.t1d});

  @override
  String get name => 'High Alarm ${alarmSettings.highMinutes}m';

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
        await t1d.targetRange5ForMins(alarmSettings.highMinutes);
    if (targets.isEmpty) {
      return true;
    }
    return targets.every((e) => e == Range5.high || e == Range5.veryHigh);
  }

  @override
  bool active() {
    return alarmSettings.highAlarm;
  }

  @override
  Future<bool> smartSnooze() async {
    var diffs = await t1d.diffPer5Minute(10);
    if (diffs.isEmpty) {
      return false;
    }

    return diffs.last < 0;
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
    return alarmSettings.urgentHighAlarm;
  }
}

class FastRiseAlarm extends Alarm {
  const FastRiseAlarm({required super.settings, required super.t1d});

  @override
  String get name => 'Fast Rise Alarm ${alarmSettings.fastRiseAlarmMinutes}';

  @override
  String get description => 'Triggers when BGL is rising quickly';

  @override
  Future<bool> trigger() async {
    // Dont trigger if High or Very High, fast drop when high is what we want
    if (t1d.targetRange5 == Range5.low || t1d.targetRange5 == Range5.veryLow) {
      return false;
    }

    // Get the diffs for the last n minutes and make sure they are all above the set delta
    var diffs = await t1d.diffPer5Minute(alarmSettings.fastRiseAlarmMinutes);
    if (diffs.isEmpty) {
      return false;
    }
    if (diffs.every((element) => element > alarmSettings.fastRiseDelta)) {
      return true;
    }
    return false;
  }

  @override
  bool active() {
    return alarmSettings.fastRiseAlarm;
  }
}

class FastDropAlarm extends Alarm {
  const FastDropAlarm({required super.settings, required super.t1d});

  @override
  String get name => 'Fast Drop Alarm ${alarmSettings.fastDropAlarmMinutes}';

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
    var diffs = await t1d.diffPer5Minute(alarmSettings.fastDropAlarmMinutes);
    if (diffs.isEmpty) {
      return false;
    }

    if (diffs.every((element) => element < alarmSettings.fastDropDelta)) {
      return true;
    }
    return false;
  }

  @override
  bool active() {
    return alarmSettings.fastDropAlarm;
  }
}

class NoDataAlarm extends Alarm {
  const NoDataAlarm({required super.settings, required super.t1d});

  @override
  String get name => 'No Data Alarm ${alarmSettings.noDataAlarmMinutes}';

  @override
  String get description => 'Triggers when no data is received';

  // This allows the alarm to still trigger with "default" even when not active
  int alarmMinutes() {
    var mins = alarmSettings.noDataAlarmMinutes;
    if (mins == -1) {
      mins = 20;
    }
    return mins;
  }

  @override
  Future<bool> trigger() async {
    if (alarmSettings.noDataAlarmMinutes == -1) {
      return false;
    }
    var lastSGV = await SGVs.lastSGV();
    if (lastSGV == null) {
      return false;
    }

    return lastSGV.age.inMinutes > alarmMinutes();
  }

  @override
  bool active() {
    return alarmSettings.noDataAlarmMinutes != -1;
  }
}
