import 'package:carer/models/sgv.dart';
import 'package:carer/services/prediction_service.dart';
import 'package:carer/services/settings/alarm_settings.dart';
import 'package:carer/services/settings/target_settings.dart';
import 'package:carer/utils/math.dart';
import 'package:clock/clock.dart';

abstract class Alarm {
  const Alarm();

  bool trigger();
  bool active();
  bool smartSnooze() {
    return false;
  }

  List<String> properties() {
    return [];
  }

  @override
  String toString() {
    return runtimeType.toString();
  }

  String status() {
    var (t, a, s) = alarmStatus();
    var name = runtimeType.toString();
    var statuses = properties();
    if (t) {
      statuses.add('T');
    }
    if (a) {
      statuses.add('A');
    }
    if (s) {
      statuses.add('S');
    }
    return '$name: (${statuses.join(",")})';
  }

  (bool, bool, bool) alarmStatus() {
    return (trigger(), active(), smartSnooze());
  }

  Range5 get targetRange5 {
    var lastSGV = CleanSGV.lastSGV.value;

    if (lastSGV == null) {
      return Range5.mid;
    }
    // Calculating Target Range
    var (tr, _) = targetRange(lastSGV.value);

    return tr;
  }

  List<Range5> targetRange5ForMins(int minsAgo) {
    var sgvs = CleanSGV.last3Hours.value.where((e) => e.minsAgo < minsAgo);
    return sgvs.map((e) {
      var (t, _) = targetRange(e.value);
      return t;
    }).toList();
  }

  List<int> diffPer5Minute(int minsAgo) {
    var sgvs = CleanSGV.last3Hours.value.where((e) => e.minsAgo < minsAgo);

    List<int> diffs = [];
    for (var sgv in sgvs) {
      diffs.add(sgv.rate5m ?? 0);
    }

    return diffs;
  }

  // Estimated mins to next reading
  DateTime currentReadingAt() {
    var lastSGV = CleanSGV.lastSGV.value;
    if (lastSGV == null) {
      return clock.now();
    }

    return lastSGV.date;
  }
}

class PredictiveLowAlarm extends Alarm {
  const PredictiveLowAlarm();

  @override
  List<String> properties() {
    return [
      "${PredictionService().getPredictionAt(at)}",
      "pRange($range)",
    ];
  }

  int get numberOfReadings => AlarmSettings().lowPredictionMinutes ~/ 5;

  DateTime get at {
    return currentReadingAt().add(Duration(minutes: numberOfReadings * 5));
  }

  Range5? get range {
    print("numberofreadings $numberOfReadings  ${PredictionService().getPredictionAt(at)}");
    return PredictionService().atPredictedTime(at);
  }

  @override
  bool trigger() {
    var r = range;
    return r == Range5.veryLow || r == Range5.low;
  }

  @override
  bool active() {
    return AlarmSettings().lowPredictionAlarm;
  }
}

class UrgentLowAlarm extends Alarm {
  const UrgentLowAlarm();

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
  List<String> properties() {
    return [
      "mins($mins)",
    ];
  }

  int get mins => AlarmSettings().lowMinutes;

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
    var range = PredictionService().atPredictedTime(clock.minutesFromNow(10));
    return range == Range5.mid;
  }
}

class HighAlarm extends Alarm {
  const HighAlarm();

  @override
  List<String> properties() {
    return [
      "mins($mins)",
    ];
  }

  int get mins => AlarmSettings().highMinutes;

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
    var range = PredictionService().atPredictedTime(clock.minutesFromNow(10));
    return range == Range5.mid;
  }
}

class UrgentHighAlarm extends Alarm {
  const UrgentHighAlarm();

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
  List<String> properties() {
    return [
      "delta(${TargetSettings().fastRiseDelta})"
          "mins($mins)",
      "diffs($diffs)",
    ];
  }

  int get mins => AlarmSettings().fastRiseAlarmMinutes;
  List<int> get diffs => diffPer5Minute(AlarmSettings().fastRiseAlarmMinutes);

  @override
  bool trigger() {
    // Dont trigger if High or Very High, fast drop when high is what we want
    if (targetRange5 == Range5.low || targetRange5 == Range5.veryLow) {
      return false;
    }

    // Get the diffs for the last n minutes and make sure they are all above the set delta
    var d = diffs;
    if (d.isEmpty) {
      return false;
    }
    if (d.every((element) => element > TargetSettings().fastRiseDelta)) {
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
  List<String> properties() {
    return [
      "delta(${TargetSettings().fastDropDelta})"
          "mins($mins)",
      "diffs($diffs)",
    ];
  }

  int get mins => AlarmSettings().fastDropAlarmMinutes;
  List<int> get diffs => diffPer5Minute(mins);

  @override
  bool trigger() {
    var tr = targetRange5;
    // Dont trigger if High or Very High, fast drop when high is what we want
    if (tr == Range5.high || tr == Range5.veryHigh) {
      return false;
    }

    // Get the diffs for the last n minutes and make sure they are all below the set delta
    var d = diffs;
    if (d.isEmpty) {
      return false;
    }

    if (d.every((element) => element < TargetSettings().fastDropDelta)) {
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
  List<String> properties() {
    return [
      "mins(${alarmMinutes()})",
    ];
  }

  int get mins => AlarmSettings().fastDropAlarmMinutes;

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
    var lastSGV = CleanSGV.lastSGV.value;
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
