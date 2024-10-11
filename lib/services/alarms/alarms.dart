import 'package:carer/models/clean_sgv.dart';
import 'package:carer/models/properties_data.dart';
import 'package:carer/services/platform_info_service.dart';
import 'package:carer/services/settings/alarm_alert_settings.dart';
import 'package:carer/services/settings/alarm_settings.dart';
import 'package:carer/services/settings/target_settings.dart';
import 'package:carer/services/settings/ui_settings.dart';
import 'package:carer/utils/math.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:unicons/unicons.dart';

class AlarmSet extends Iterable<AlarmType> {
  final Set<AlarmType> _alarms;

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
  Iterator<AlarmType> get iterator => _alarms.iterator;

  @override
  String toString() {
    return _alarms.toString();
  }
}

// TODO this is a step towards having all alarms as static
enum AlarmType {
  urgentLow(_UrgentLowAlarm()),
  low(_LowAlarm()),
  high(_HighAlarm()),
  urgentHigh(_UrgentHighAlarm()),
  fastRise(_FastRiseAlarm()),
  fastDrop(_FastDropAlarm()),
  noData(_NoDataAlarm()),
  lowBattery(_LowBatteryAlarm());

  final AlarmMethods methods;
  const AlarmType(this.methods);

  bool trigger() {
    return methods.trigger();
  }

  bool active() {
    return methods.active();
  }

  bool smartSnooze() {
    return methods.smartSnooze();
  }

  Map<String, dynamic> conditions() {
    return methods.conditions();
  }

  String shortSummary() {
    return methods.shortSummary();
  }

  IconData get icon {
    return methods.icon();
  }

  (bool, bool, bool) alarmStatus() {
    return methods.alarmStatus();
  }

  static AlarmType fromName(String name) {
    for (var alarm in AlarmType.values) {
      if (alarm.name == name) {
        return alarm;
      }
    }
    throw ArgumentError("Invalid Alarm Name: $name");
  }
}

abstract class AlarmMethods {
  const AlarmMethods();

  bool trigger();
  bool active();
  bool smartSnooze() {
    return false;
  }

  Map<String, dynamic> conditions() {
    CleanSGV? lastSGV = CleanSGV.lastSGV.value;
    return {
      "lastSGV": lastSGV?.value,
      "LastSGVStr": lastSGVStr(),
      "lastSGVAgeInMinutes": lastSGV?.age.inMinutes,
      "diffs": diffPer5Minute(30),
      "targetRange5": targetRange5.name,
      "previousReadings": lastSGV?.before5,
      "predictions": lastSGV?.predictions,
    };
  }

  @override
  String toString() {
    return runtimeType.toString();
  }

  String shortSummary();
  IconData icon();

  (bool, bool, bool) alarmStatus() {
    return (trigger(), active(), smartSnooze());
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
    var lastSGV = CleanSGV.lastSGV.value;
    if (lastSGV == null) {
      return "?";
    }
    return lastSGV.unitStr();
  }

  String unitStr(int value) {
    return UISettings().unit.str(value);
  }

  CleanSGV? getPredictedValue(int numberOfReadings) {
    var lastSGV = CleanSGV.lastSGV.value;
    if (lastSGV == null) {
      return null;
    }

    return lastSGV.getPredictedValue(numberOfReadings);
  }
}

class _UrgentLowAlarm extends AlarmMethods {
  const _UrgentLowAlarm();

  @override
  IconData icon() => UniconsLine.temperature_minus;

  @override
  String shortSummary() => "Urgent Low (<${unitStr(TargetSettings().lowUrgent)})";

  @override
  bool trigger() {
    return targetRange5 == Range5.veryLow;
  }

  @override
  bool active() {
    return AlarmSettings().urgentLowAlarm;
  }
}

class _LowAlarm extends AlarmMethods {
  const _LowAlarm();

  @override
  String shortSummary() {
    if (_lowTrigger()) {
      return "Low (<${unitStr(TargetSettings().lowTarget)})";
    }
    if (_predictiveTrigger()) {
      var sgv = getPredictedValue(numberOfReadings);
      if (sgv == null) {
        return "?";
      }
      return "Predicted Low (<${unitStr(TargetSettings().lowTarget)})";
    }
    return "?";
  }

  @override
  IconData icon() => UniconsLine.temperature_empty;

  @override
  Map<String, dynamic> conditions() {
    return super.conditions()
      ..addAll({
        "numberOfReadings": numberOfReadings,
        "prediction": getPredictedValue(numberOfReadings),
      });
  }

  bool _lowTrigger() {
    return targetRange5 == Range5.low || targetRange5 == Range5.veryLow;
  }

  @override
  bool trigger() {
    return _lowTrigger() || _predictiveTrigger();
  }

  ///
  // Predictive Bit of the Alarm
  ///

  int get numberOfReadings => AlarmSettings().lowPredictionMinutes ~/ 5;

  bool _predictiveTrigger() {
    if (!AlarmSettings().lowPredictionAlarm) {
      return false;
    }

    // Do not trigger predictive low if data is 15 mins out of date so like 3-4 readings
    var lastSGV = CleanSGV.lastSGV.value;
    if (lastSGV == null) {
      return false;
    }

    if (lastSGV.age > const Duration(minutes: 15)) {
      return false;
    }

    // Check prediction
    var sgv = getPredictedValue(numberOfReadings);

    if (sgv == null) {
      return false;
    }

    return sgv.range == Range5.veryLow || sgv.range == Range5.low;
  }

  @override
  bool active() {
    return AlarmSettings().lowAlarm;
  }
}

class _HighAlarm extends AlarmMethods {
  const _HighAlarm();

  @override
  IconData icon() => UniconsLine.temperature;

  @override
  String shortSummary() {
    if (smartSnooze()) {
      return "High Smart Snooze (<${unitStr(TargetSettings().highTarget)})";
    }
    return "High (>${unitStr(TargetSettings().highTarget)})";
  }

  @override
  Map<String, dynamic> conditions() {
    return super.conditions()
      ..addAll({
        "mins": mins,
      });
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
    CleanSGV? sgv = getPredictedValue(3);
    if (sgv == null) {
      return false;
    }
    var range = sgv.range;
    return AlarmAlertSettings().smartSnoozeHigh && range == Range5.mid;
  }
}

class _UrgentHighAlarm extends AlarmMethods {
  const _UrgentHighAlarm();

  @override
  IconData icon() => UniconsLine.temperature_plus;

  @override
  String shortSummary() => "Urgent High (>${unitStr(TargetSettings().highUrgent)})";

  @override
  bool trigger() {
    return targetRange5 == Range5.veryHigh;
  }

  @override
  bool active() {
    return AlarmSettings().urgentHighAlarm;
  }
}

class _FastRiseAlarm extends AlarmMethods {
  const _FastRiseAlarm();

  @override
  IconData icon() => UniconsLine.angle_double_up;

  @override
  String shortSummary() => "Fast Rise (<${unitStr(TargetSettings().fastRiseDelta)})";

  @override
  Map<String, dynamic> conditions() {
    return super.conditions()
      ..addAll({
        "delta": TargetSettings().fastRiseDelta,
        "mins": mins,
      });
  }

  int get mins => AlarmSettings().fastRiseAlarmMinutes;
  List<int> get diffs => diffPer5Minute(mins);

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
    return AlarmSettings().fastRiseAlarmMinutes > 0;
  }
}

class _FastDropAlarm extends AlarmMethods {
  const _FastDropAlarm();

  @override
  IconData icon() => UniconsLine.angle_double_down;

  @override
  String shortSummary() => "Fast Drop (<${unitStr(TargetSettings().fastDropDelta)})";

  @override
  Map<String, dynamic> conditions() {
    return super.conditions()
      ..addAll({
        "delta": TargetSettings().fastDropDelta,
        "mins": mins,
      });
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
    return AlarmSettings().fastDropAlarmMinutes > 0;
  }
}

class _NoDataAlarm extends AlarmMethods {
  const _NoDataAlarm();

  @override
  IconData icon() => UniconsLine.x;

  @override
  String shortSummary() => "No Data for ${age.inMinutes}m";

  @override
  Map<String, dynamic> conditions() {
    return super.conditions()
      ..addAll({
        "mins": alarmMinutes(),
      });
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
    if (AlarmSettings().noDataAlarmMinutes > 0) {
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
    return AlarmSettings().noDataAlarmMinutes > 0;
  }
}

class _LowBatteryAlarm extends AlarmMethods {
  const _LowBatteryAlarm();

  @override
  IconData icon() => UniconsLine.battery_empty;

  @override
  Map<String, dynamic> conditions() {
    return super.conditions()
      ..addAll({
        "thisCharging": PlatformInfoService().thisPhoneIsCharging(),
        "thisBattery": PlatformInfoService().thisPhonesBatteryLevel(),
        "t1dCharging": PropertiesData().t1dPhoneIsCharging(),
        "t1dBattery": PropertiesData().t1dPhonesBatteryLevel(),
      });
  }

  @override
  String shortSummary() {
    var statusStr = [];
    if (_carerTrigger()) {
      statusStr.add("This Battery");
    }
    if (_t1DTrigger()) {
      statusStr.add("T1D Battery(${PropertiesData().t1dPhonesBatteryLevel()}%)");
    }

    return "${statusStr.join(" and ")} < 10%";
  }

  @override
  bool trigger() {
    return _carerTrigger() || _t1DTrigger();
  }

  bool _carerTrigger() {
    if (!AlarmSettings().carerBatteryAlarm) {
      return false;
    }
    return PlatformInfoService().thisPhonesBatteryLevel() < 10 && !PlatformInfoService().thisPhoneIsCharging();
  }

  bool _t1DTrigger() {
    if (!AlarmSettings().t1dBatteryAlarm) {
      return false;
    }
    return PropertiesData().t1dPhonesBatteryLevel() < 10 && !PropertiesData().t1dPhoneIsCharging();
  }

  @override
  bool active() {
    return AlarmSettings().carerBatteryAlarm || AlarmSettings().t1dBatteryAlarm;
  }
}
