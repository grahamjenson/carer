import 'package:carer/models/settings/alarm_settings.dart';
import 'package:carer/models/settings_cn.dart';
import 'package:carer/models/t1d_cn.dart';
import 'package:carer/utils/math.dart';

abstract class Alarm {
  final Settings settings;
  AlarmSettings get alarmSettings => settings.alarmSettings;
  final T1DCN t1d;

  const Alarm({required this.settings, required this.t1d});

  String get name;
  String get description;

  bool trigger();
  bool active();
  bool smartSnooze() {
    return false;
  }
}

class UrgentLowAlarm extends Alarm {
  const UrgentLowAlarm({required super.settings, required super.t1d});

  @override
  String get name => 'Urgent Low Alarm';

  @override
  String get description => 'Triggers when BGL is below the urgent low target';

  @override
  bool trigger() {
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
  String get name => 'Low Alarm ${alarmSettings.lowMinutes}m ${smartSnooze()}';

  @override
  String get description =>
      'Triggers when all BGLs for a time period are below the low target';

  @override
  bool trigger() {
    var latest =
        t1d.targetRange5 == Range5.low || t1d.targetRange5 == Range5.veryLow;
    if (!latest) {
      return false;
    }
    List<Range5> targets = t1d.targetRange5ForMins(alarmSettings.lowMinutes);
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
  bool smartSnooze() {
    var diffs = t1d.diffPer5Minute(5);
    if (diffs.isEmpty) {
      return false;
    }

    return diffs.last > 0;
  }
}

class HighAlarm extends Alarm {
  const HighAlarm({required super.settings, required super.t1d});

  @override
  String get name =>
      'High Alarm ${alarmSettings.highMinutes}m ${smartSnooze()}';

  @override
  String get description =>
      'Triggers when all BGLs for a time period are above the high target';

  @override
  bool trigger() {
    var latest =
        t1d.targetRange5 == Range5.high || t1d.targetRange5 == Range5.veryHigh;
    if (!latest) {
      return false;
    }
    List<Range5> targets = t1d.targetRange5ForMins(alarmSettings.highMinutes);
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
  bool smartSnooze() {
    var diffs = t1d.diffPer5Minute(5);
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
  bool trigger() {
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
  bool trigger() {
    // Dont trigger if High or Very High, fast drop when high is what we want
    if (t1d.targetRange5 == Range5.low || t1d.targetRange5 == Range5.veryLow) {
      return false;
    }

    // Get the diffs for the last n minutes and make sure they are all above the set delta
    var diffs = t1d.diffPer5Minute(alarmSettings.fastRiseAlarmMinutes);
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
  bool trigger() {
    // Dont trigger if High or Very High, fast drop when high is what we want
    if (t1d.targetRange5 == Range5.high ||
        t1d.targetRange5 == Range5.veryHigh) {
      return false;
    }

    // Get the diffs for the last n minutes and make sure they are all below the set delta
    var diffs = t1d.diffPer5Minute(alarmSettings.fastDropAlarmMinutes);
    if (diffs.isEmpty) {
      return false;
    }

    if (diffs.every((element) => element < -alarmSettings.fastDropDelta)) {
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

  @override
  bool trigger() {
    if (t1d.summary.lastSGV == null) {
      return false;
    }

    return t1d.summary.lastSGV!.age.inMinutes >
        alarmSettings.noDataAlarmMinutes;
  }

  @override
  bool active() {
    return alarmSettings.noDataAlarmMinutes != -1;
  }
}
