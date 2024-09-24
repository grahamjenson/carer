import 'package:carer/models/clean_sgv.dart';
import 'package:carer/models/properties_data.dart';
import 'package:carer/services/platform_info_service.dart';
import 'package:carer/services/prediction_service.dart';
import 'package:carer/services/settings/alarm_alert_settings.dart';
import 'package:carer/services/settings/alarm_settings.dart';
import 'package:carer/services/settings/target_settings.dart';
import 'package:carer/services/settings/ui_settings.dart';
import 'package:carer/utils/math.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:unicons/unicons.dart';

class AlarmSet extends Iterable<Alarm> {
  final Set<Alarm> _alarms;

  AlarmSet(this._alarms);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlarmSet && runtimeType == other.runtimeType && _alarms.length == other._alarms.length && _alarms.containsAll(other._alarms);

  @override
  int get hashCode => _alarms.fold(0, (prev, alarm) => prev ^ alarm.hashCode);

  @override
  bool get isNotEmpty => _alarms.isNotEmpty;

  @override
  bool get isEmpty => _alarms.isEmpty;

  @override
  Iterator<Alarm> get iterator => _alarms.iterator;

  @override
  String toString() {
    return _alarms.toString();
  }
}

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

  String status();
  IconData icon();

  (bool, bool, bool) alarmStatus() {
    return (trigger(), active(), smartSnooze());
  }

  int lastSgvReading() {
    var lastSGV = CleanSGV.lastSGV.value;
    if (lastSGV == null) {
      return 0;
    }
    return lastSGV.value;
  }

  Range5 get targetRange5 {
    var lastSGV = CleanSGV.lastSGV.value;

    if (lastSGV == null) {
      return Range5.mid;
    }

    return lastSGV.range;
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

  String lastSGVStr() {
    return unitStr(lastSgvReading());
  }

  String unitStr(int value) {
    return UISettings().unit.str(value);
  }
}

class PredictiveLowAlarm extends Alarm {
  const PredictiveLowAlarm();

  @override
  List<String> properties() {
    return [
      "${PredictionService().getReadingsAhead(numberOfReadings)}",
      "pRange($range)",
    ];
  }

  @override
  IconData icon() => UniconsLine.windsock;

  @override
  String status() =>
      "Predictive Low ${unitStr(PredictionService().getReadingsAheadValue(numberOfReadings))} < ${unitStr(TargetSettings().lowTarget)}";

  int get numberOfReadings => AlarmSettings().lowPredictionMinutes ~/ 5;

  Range5? get range {
    CleanSGV? sgv = PredictionService().getReadingsAhead(numberOfReadings);
    if (sgv == null) {
      return null;
    }
    var (range, _) = targetRange(sgv.value);
    return range;
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
  IconData icon() => UniconsLine.temperature_minus;

  @override
  String status() => "Urgent Low  ${lastSGVStr()} < ${unitStr(TargetSettings().lowUrgent)}";

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
  String status() => "Low ${lastSGVStr()} < ${unitStr(TargetSettings().lowTarget)}";

  @override
  IconData icon() => UniconsLine.temperature_empty;

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
}

class HighAlarm extends Alarm {
  const HighAlarm();

  @override
  IconData icon() => UniconsLine.temperature;

  @override
  String status() {
    if (smartSnooze()) {
      return "High ${lastSGVStr()} > ${unitStr(TargetSettings().highTarget)} (Smart Snooze)";
    }
    return "High ${lastSGVStr()} > ${unitStr(TargetSettings().highTarget)}";
  }

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
    // TODO: make readings ahead adjustable
    CleanSGV? sgv = PredictionService().getReadingsAhead(3);
    if (sgv == null) {
      return false;
    }
    var (range, _) = targetRange(sgv.value);
    return AlarmAlertSettings().smartSnoozeHigh && range == Range5.mid;
  }
}

class UrgentHighAlarm extends Alarm {
  const UrgentHighAlarm();

  @override
  IconData icon() => UniconsLine.temperature_plus;

  @override
  String status() => "Urgent High ${lastSGVStr()} > ${unitStr(TargetSettings().highUrgent)}";

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
  IconData icon() => UniconsLine.angle_double_up;

  @override
  String status() => "Fast Rise < ${unitStr(TargetSettings().fastRiseDelta)}";

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
  IconData icon() => UniconsLine.angle_double_down;

  @override
  String status() => "Fast Drop > ${unitStr(TargetSettings().fastDropDelta)}";

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
  IconData icon() => UniconsLine.x;

  @override
  String status() => "No Data ${age.inMinutes}m > ${alarmMinutes()}m";

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

    return age.inMinutes > alarmMinutes();
  }

  Duration get age {
    var lastSGV = CleanSGV.lastSGV.value;
    if (lastSGV == null) {
      return Duration.zero;
    }
    return lastSGV.age;
  }

  @override
  bool active() {
    return AlarmSettings().noDataAlarmMinutes != -1;
  }
}

class CarerPhoneLowBatteryAlarm extends Alarm {
  const CarerPhoneLowBatteryAlarm();

  @override
  IconData icon() => UniconsLine.battery_empty;

  @override
  String status() => "This Phones Battery ${carerBatteryLevel()}% < 30%";

  @override
  bool trigger() {
    // Less than 30% and not charging
    return carerBatteryLevel() < 30 && !carerBatteryCharging();
  }

  @override
  bool active() {
    return AlarmSettings().carerBatteryAlarm;
  }

  int carerBatteryLevel() {
    return PlatformInfoService().batteryLevel.value;
  }

  bool carerBatteryCharging() {
    var bm = PlatformInfoService().batteryMode.value;
    return bm == BatteryMode.charging;
  }
}

class T1DPhoneLowBatteryAlarm extends Alarm {
  const T1DPhoneLowBatteryAlarm();

  @override
  IconData icon() => UniconsLine.battery_empty;

  @override
  String status() => "Uploader/T1D Phones Battery  ${t1dBatteryLevel()}% < 30";

  @override
  bool trigger() {
    return t1dBatteryLevel() < 30 && !t1dBatteryCharning();
  }

  int t1dBatteryLevel() {
    return PropertiesData().battery.toInt();
  }

  bool t1dBatteryCharning() {
    return PropertiesData().isCharging;
  }

  @override
  bool active() {
    return AlarmSettings().t1dBatteryAlarm;
  }
}
