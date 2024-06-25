import 'package:carer/models/sgv.dart';
import 'package:carer/services/prediction_service.dart';
import 'package:carer/services/settings/alarm_settings.dart';
import 'package:carer/services/settings/target_settings.dart';
import 'package:carer/utils/math.dart';

abstract class Alarm {
  const Alarm();

  String get name;
  String get description;

  bool trigger();
  bool active();
  bool smartSnooze() {
    return false;
  }

  Range5 get targetRange5 {
    var lastSGV = SGV.lastSGV().value;
    if (lastSGV == null) {
      return Range5.mid;
    }
    // Calculating Target Range
    var (tr, _) = targetRange(lastSGV.value);
    return tr;
  }

  List<Range5> targetRange5ForMins(int minsAgo) {
    var sgvs = SGV.last3Hours().value!.where((e) => e.minsAgo < minsAgo);
    return sgvs.map((e) {
      var (t, _) = targetRange(e.value);
      return t;
    }).toList();
  }

  List<int> diffPer5Minute(int minsAgo) {
    var sgvs = SGV.last3Hours().value!.where((e) => e.minsAgo < minsAgo);

    List<int> diffs = [];
    for (var sgv in sgvs) {
      diffs.add(sgv.rate5m ?? 0);
    }

    return diffs;
  }
}

class PredictiveLowAlarm extends Alarm {
  const PredictiveLowAlarm();

  @override
  String get name => 'PredictiveLowAlarm Low Alarm';

  @override
  String get description => 'Triggers when it predicts a low in ${AlarmSettings().lowPredictionMinutes}m';

  @override
  bool trigger() {
    var range = PredictionService().atPredictedTime(AlarmSettings().lowPredictionMinutes);
    return range == Range5.veryLow || range == Range5.low;
  }

  @override
  bool active() {
    return AlarmSettings().lowPredictionAlarm;
  }
}

class UrgentLowAlarm extends Alarm {
  const UrgentLowAlarm();

  @override
  String get name => 'Urgent Low Alarm';

  @override
  String get description => 'Triggers when BGL is below the urgent low target';

  @override
  bool trigger() {
    return targetRange5 == Range5.veryLow;
  }

  @override
  bool active() {
    return AlarmSettings().urgentLowAlarm;
  }
}

class LowAlarm extends Alarm {
  const LowAlarm();

  @override
  String get name => 'Low Alarm ${AlarmSettings().lowMinutes}m ${smartSnooze()}';

  @override
  String get description => 'Triggers when all BGLs for a time period are below the low target';

  @override
  bool trigger() {
    var latest = targetRange5 == Range5.low || targetRange5 == Range5.veryLow;
    if (!latest) {
      return false;
    }
    List<Range5> targets = targetRange5ForMins(AlarmSettings().lowMinutes);
    if (targets.isEmpty) {
      return true;
    }
    return targets.every((e) => e == Range5.low || e == Range5.veryLow);
  }

  @override
  bool active() {
    return AlarmSettings().lowAlarm;
  }

  @override
  bool smartSnooze() {
    var range = PredictionService().atPredictedTime(10);
    return range == Range5.mid;
  }
}

class HighAlarm extends Alarm {
  const HighAlarm();

  @override
  String get name => 'High Alarm ${AlarmSettings().highMinutes}m ${smartSnooze()}';

  @override
  String get description => 'Triggers when all BGLs for a time period are above the high target';

  @override
  bool trigger() {
    var tr = targetRange5;

    var latest = tr == Range5.high || tr == Range5.veryHigh;
    if (!latest) {
      return false;
    }
    List<Range5> targets = targetRange5ForMins(AlarmSettings().highMinutes);
    if (targets.isEmpty) {
      return true;
    }
    return targets.every((e) => e == Range5.high || e == Range5.veryHigh);
  }

  @override
  bool active() {
    return AlarmSettings().highAlarm;
  }

  @override
  bool smartSnooze() {
    var range = PredictionService().atPredictedTime(10);
    return range == Range5.mid;
  }
}

class UrgentHighAlarm extends Alarm {
  const UrgentHighAlarm();

  @override
  String get name => 'Urgent High Alarm';

  @override
  String get description => 'Triggers when BGL is above the urgent high target';

  @override
  bool trigger() {
    return targetRange5 == Range5.veryHigh;
  }

  @override
  bool active() {
    return AlarmSettings().urgentHighAlarm;
  }
}

class FastRiseAlarm extends Alarm {
  const FastRiseAlarm();

  @override
  String get name => 'Fast Rise Alarm ${AlarmSettings().fastRiseAlarmMinutes}';

  @override
  String get description => 'Triggers when BGL is rising quickly';

  @override
  bool trigger() {
    // Dont trigger if High or Very High, fast drop when high is what we want
    if (targetRange5 == Range5.low || targetRange5 == Range5.veryLow) {
      return false;
    }

    // Get the diffs for the last n minutes and make sure they are all above the set delta
    var diffs = diffPer5Minute(AlarmSettings().fastRiseAlarmMinutes);
    if (diffs.isEmpty) {
      return false;
    }
    if (diffs.every((element) => element > TargetSettings().fastRiseDelta)) {
      return true;
    }
    return false;
  }

  @override
  bool active() {
    return AlarmSettings().fastRiseAlarm;
  }
}

class FastDropAlarm extends Alarm {
  const FastDropAlarm();

  @override
  String get name => 'Fast Drop Alarm ${AlarmSettings().fastDropAlarmMinutes}';

  @override
  String get description => 'Triggers when BGL is dropping quickly';

  @override
  bool trigger() {
    // Dont trigger if High or Very High, fast drop when high is what we want
    if (targetRange5 == Range5.high || targetRange5 == Range5.veryHigh) {
      return false;
    }

    // Get the diffs for the last n minutes and make sure they are all below the set delta
    var diffs = diffPer5Minute(AlarmSettings().fastDropAlarmMinutes);
    if (diffs.isEmpty) {
      return false;
    }

    if (diffs.every((element) => element < TargetSettings().fastDropDelta)) {
      return true;
    }
    return false;
  }

  @override
  bool active() {
    return AlarmSettings().fastDropAlarm;
  }
}

class NoDataAlarm extends Alarm {
  const NoDataAlarm();

  @override
  String get name => 'No Data Alarm ${AlarmSettings().noDataAlarmMinutes}';

  @override
  String get description => 'Triggers when no data is received';

  // This allows the alarm to still trigger with "default" even when not active
  int alarmMinutes() {
    var mins = AlarmSettings().noDataAlarmMinutes;
    if (mins == -1) {
      mins = 20;
    }
    return mins;
  }

  @override
  bool trigger() {
    if (AlarmSettings().noDataAlarmMinutes == -1) {
      return false;
    }
    var lastSGV = SGV.lastSGV().value;
    if (lastSGV == null) {
      return false;
    }
    return lastSGV.age.inMinutes > alarmMinutes();
  }

  @override
  bool active() {
    return AlarmSettings().noDataAlarmMinutes != -1;
  }
}
