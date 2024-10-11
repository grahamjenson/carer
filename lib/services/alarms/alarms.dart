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

  AlarmSet difference(AlarmSet other) {
    return AlarmSet(_alarms.difference(other._alarms));
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

  final AlarmMethods _methods;
  const AlarmType(this._methods);

  bool trigger() {
    return _methods.trigger();
  }

  bool active() {
    return _methods.active();
  }

  bool smartSnooze() {
    return _methods.smartSnooze();
  }

  Map<String, dynamic> conditions() {
    return _methods.conditions();
  }

  String shortSummary() {
    return _methods.shortSummary();
  }

  IconData get icon {
    return _methods.icon();
  }

  (bool, bool, bool) alarmStatus() {
    return _methods.alarmStatus();
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

  get minutesToTrigger => -1;
  get numberOfReadingsToTrigger => minutesToTrigger ~/ 5;

  Map<String, dynamic> conditions() {
    CleanSGV? lastSGV = CleanSGV.lastSGV.value;
    return {
      "lastSGV": lastSGV?.toString(),
      "LastSGVStr": lastSGVStr(),
      "lastSGVAgeInMinutes": lastSGV?.age.inMinutes,
      "targetRange5": targetRange5.name,
      "prediction": getPredictedValue(numberOfReadingsToTrigger)?.toString(),
      "previousReadings": lastSGV?.before12.map((e) => e.toString()).toList(),
      "predictions": lastSGV?.predictions?.map((e) => e?.toString()).toList(),
      "minutesToTrigger": minutesToTrigger,
      "numberOfReadingsToTriggerPrediction": numberOfReadingsToTrigger,
      "targetRange5ForReadings": targetRange5ForReadings(numberOfReadingsToTrigger).map((e) => e.name).toList(),
      "diffs": diffPer5MinuteForReadings(numberOfReadingsToTrigger),
      "targets": [TargetSettings().lowUrgent, TargetSettings().lowTarget, TargetSettings().highTarget, TargetSettings().highUrgent],
      "fastDropRise": [TargetSettings().fastDropDelta, TargetSettings().fastRiseDelta],
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

  List<Range5> targetRange5ForReadings(int numberOfReadings) {
    var lastSGV = CleanSGV.lastSGV.value;

    if (lastSGV == null) {
      return [];
    }

    var sgvs = lastSGV.lastNReadings(numberOfReadings);
    if (sgvs.isEmpty || sgvs.length != numberOfReadings + 1) {
      return [];
    }
    return sgvs.map((e) {
      var (t, _) = targetRange(e.value);
      return t;
    }).toList();
  }

  List<int> diffPer5MinuteForReadings(int numberOfReadings) {
    var lastSGV = CleanSGV.lastSGV.value;

    if (lastSGV == null) {
      return [];
    }

    var sgvs = lastSGV.lastNReadings(numberOfReadings);
    if (sgvs.isEmpty || sgvs.length != numberOfReadings + 1) {
      return [];
    }

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
  get minutesToTrigger => AlarmSettings().lowPredictionMinutes;

  @override
  String shortSummary() {
    if (_lowTrigger()) {
      return "Low (<${unitStr(TargetSettings().lowTarget)})";
    }
    if (_predictiveTrigger()) {
      var sgv = getPredictedValue(numberOfReadingsToTrigger);
      if (sgv == null) {
        return "?";
      }
      return "Predicted Low (<${unitStr(TargetSettings().lowTarget)})";
    }
    return "?";
  }

  @override
  IconData icon() => UniconsLine.temperature_empty;

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
    var sgv = getPredictedValue(numberOfReadingsToTrigger);

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
  get minutesToTrigger => AlarmSettings().highMinutes;

  @override
  bool trigger() {
    var tr = targetRange5;

    var latest = tr == Range5.high || tr == Range5.veryHigh;
    if (!latest) {
      return false;
    }
    List<Range5> targets = targetRange5ForReadings(numberOfReadingsToTrigger);
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
  int get minutesToTrigger => AlarmSettings().fastRiseAlarmMinutes;

  List<int> get diffs => diffPer5MinuteForReadings(numberOfReadingsToTrigger);

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
  int get minutesToTrigger => AlarmSettings().fastDropAlarmMinutes;
  List<int> get diffs => diffPer5MinuteForReadings(numberOfReadingsToTrigger);

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
  int get minutesToTrigger {
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

    return age.inMinutes > minutesToTrigger;
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
