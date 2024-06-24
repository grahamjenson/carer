import 'package:carer/models/sgv.dart';
import 'package:carer/predictors/regressions.dart';
import 'package:carer/predictors/sgv_predictors.dart';
import 'package:carer/signals/settings/alarm_settings.dart';
import 'package:carer/signals/t1d_cn.dart';
import 'package:carer/utils/math.dart';

Future<Range5> atPredictedTime(int mins) async {
  Exp2Predictor exp2predictor = Exp2Predictor();
  await exp2predictor.init();
  if (exp2predictor.regression.runtimeType == NoopRegression) {
    print("Regression noop");
    return Range5.mid;
  }
  var sgvAtTime = exp2predictor.predictMin(mins);
  var (range, _) = targetRange(sgvAtTime.value.toInt());
  return range;
}

abstract class Alarm {
  final T1DCN t1d;

  const Alarm({required this.t1d});

  String get name;
  String get description;

  Future<bool> trigger();
  bool active();
  Future<bool> smartSnooze() async {
    return false;
  }
}

class PredictiveLowAlarm extends Alarm {
  const PredictiveLowAlarm({required super.t1d});

  @override
  String get name => 'PredictiveLowAlarm Low Alarm';

  @override
  String get description =>
      'Triggers when it predicts a low in ${AlarmSettings().lowPredictionMinutes}m';

  @override
  Future<bool> trigger() async {
    var range = await atPredictedTime(AlarmSettings().lowPredictionMinutes);
    return range == Range5.veryLow || range == Range5.low;
  }

  @override
  bool active() {
    return AlarmSettings().lowPredictionAlarm;
  }
}

class UrgentLowAlarm extends Alarm {
  const UrgentLowAlarm({required super.t1d});

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
    return AlarmSettings().urgentLowAlarm;
  }
}

class LowAlarm extends Alarm {
  const LowAlarm({required super.t1d});

  @override
  String get name => 'Low Alarm ${AlarmSettings().lowMinutes}m';

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
    List<Range5> targets = t1d.targetRange5ForMins(AlarmSettings().lowMinutes);
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
  Future<bool> smartSnooze() async {
    var range = await atPredictedTime(10);

    return range == Range5.mid;
  }
}

class HighAlarm extends Alarm {
  const HighAlarm({required super.t1d});

  @override
  String get name => 'High Alarm ${AlarmSettings().highMinutes}m';

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
    List<Range5> targets = t1d.targetRange5ForMins(AlarmSettings().highMinutes);
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
  Future<bool> smartSnooze() async {
    var range = await atPredictedTime(10);
    return range == Range5.mid;
  }
}

class UrgentHighAlarm extends Alarm {
  const UrgentHighAlarm({required super.t1d});

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
    return AlarmSettings().urgentHighAlarm;
  }
}

class FastRiseAlarm extends Alarm {
  const FastRiseAlarm({required super.t1d});

  @override
  String get name => 'Fast Rise Alarm ${AlarmSettings().fastRiseAlarmMinutes}';

  @override
  String get description => 'Triggers when BGL is rising quickly';

  @override
  Future<bool> trigger() async {
    // Dont trigger if High or Very High, fast drop when high is what we want
    if (t1d.targetRange5 == Range5.low || t1d.targetRange5 == Range5.veryLow) {
      return false;
    }

    // Get the diffs for the last n minutes and make sure they are all above the set delta
    var diffs = t1d.diffPer5Minute(AlarmSettings().fastRiseAlarmMinutes);
    if (diffs.isEmpty) {
      return false;
    }
    if (diffs.every((element) => element > AlarmSettings().fastRiseDelta)) {
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
  const FastDropAlarm({required super.t1d});

  @override
  String get name => 'Fast Drop Alarm ${AlarmSettings().fastDropAlarmMinutes}';

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
    var diffs = t1d.diffPer5Minute(AlarmSettings().fastDropAlarmMinutes);
    if (diffs.isEmpty) {
      return false;
    }

    if (diffs.every((element) => element < AlarmSettings().fastDropDelta)) {
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
  const NoDataAlarm({required super.t1d});

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
  Future<bool> trigger() async {
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
