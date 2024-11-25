import 'package:carer/models/clean_sgv.dart';
import 'package:carer/models/properties_data.dart';
import 'package:carer/models/sql/sgv.dart';
import 'package:carer/services/app_details_service.dart';
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
  lowBattery(_LowBatteryAlarm()),
  unknown(_Unkown());

  final AlarmMethods _methods;
  const AlarmType(this._methods);

  bool trigger() => _methods.trigger();

  bool active() => _methods.active();

  bool smartSnooze() => _methods.smartSnooze();

  Map<String, dynamic> details() => _methods.details();

  String get description => _methods.description;
  String get title => _methods.title;
  String shortSummary() => _methods.shortSummary();
  String statment() => _methods.statment();

  IconData get icon => _methods.icon();

  (bool, bool, bool) alarmStatus() => _methods.alarmStatus();

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

  Map<String, dynamic> details() {
    var map = AppDetailsService().appDetails();

    map.addAll({
      "targetRange5": targetRange5.name,
      "prediction": getPredictedValue(numberOfReadingsToTrigger)?.toString(),
      "minutesToTrigger": minutesToTrigger,
      "numberOfReadingsToTriggerPrediction": numberOfReadingsToTrigger,
      "targetRange5ForReadings": targetRange5s.map((e) => e.name).toList(),
      "diffs": diffs.map(unitStr).toList(),
      "targets": [
        unitStr(TargetSettings().lowUrgent),
        unitStr(TargetSettings().lowTarget),
        unitStr(TargetSettings().highTarget),
        unitStr(TargetSettings().highUrgent),
      ],
      "fastDropRise": [
        unitStr(TargetSettings().fastDropDelta),
        unitStr(TargetSettings().fastRiseDelta),
      ],
    });
    return map;
  }

  @override
  String toString() {
    return runtimeType.toString();
  }

  String get description;
  String get title;
  String shortSummary();
  String statment();
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

  List<Range5> get targetRange5s {
    if (minutesToTrigger < 0) {
      return [];
    }
    var lastSGV = CleanSGV.lastSGV.value;

    if (lastSGV == null) {
      return [];
    }

    var sgvs = lastSGV.lastReadingsAfter(Duration(minutes: minutesToTrigger));
    if (sgvs.isEmpty) {
      return [];
    }
    return sgvs.map((e) {
      var (t, _) = targetRange(e.value);
      return t;
    }).toList();
  }

  List<int> get diffs {
    if (minutesToTrigger < 0) {
      return [];
    }
    var lastSGV = CleanSGV.lastSGV.value;

    if (lastSGV == null) {
      return [];
    }

    var sgvs = lastSGV.lastReadingsAfter(Duration(minutes: minutesToTrigger));
    if (sgvs.isEmpty) {
      return [];
    }

    List<int> diffs = [];

    for (var sgv in sgvs) {
      if (sgv.rate5m == null) {
        continue;
      }
      diffs.add(sgv.rate5m!);
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

  String unitStr(num value) {
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

class _Unkown extends AlarmMethods {
  const _Unkown();

  @override
  String get title => "Unknown Alarm";

  @override
  IconData icon() => UniconsLine.question_circle;

  @override
  String get description => "Unknown Alarm";

  @override
  String shortSummary() => "Unknown Alarm";

  @override
  String statment() => "Unknown Alarm";

  @override
  bool trigger() => false;

  @override
  bool active() => false;
}

class _UrgentLowAlarm extends AlarmMethods {
  const _UrgentLowAlarm();

  @override
  IconData icon() => UniconsLine.temperature_minus;

  @override
  String get title => "Urgent Low Alarm";

  @override
  String get description {
    var unit = UISettings().unit;
    String description = "Alarm Below ${unit.str(TargetSettings().lowUrgent)}";
    if (!AlarmSettings().urgentLowAlarm) {
      description = "Off";
    }
    return description;
  }

  @override
  String shortSummary() => "Urgent Low <${unitStr(TargetSettings().lowUrgent)}";

  @override
  String statment() => "Urgent Low";

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
  String get title => "Low Alarm";

  @override
  String get description {
    var unit = UISettings().unit;
    String description = "Alarm Below ${unit.str(TargetSettings().lowTarget)}";
    if (AlarmSettings().lowPredictionAlarm) {
      description += " (w/ Predictive Low in ${AlarmSettings().lowPredictionMinutes}m)";
    }
    if (!AlarmSettings().lowAlarm) {
      description = "Off";
    }
    return description;
  }

  @override
  String shortSummary() {
    if (_lowTrigger()) {
      return "Low <${unitStr(TargetSettings().lowTarget)}";
    }
    if (_predictiveTrigger()) {
      var sgv = getPredictedValue(numberOfReadingsToTrigger);
      if (sgv == null) {
        return "?";
      }
      return "Predicted Low <${unitStr(TargetSettings().lowTarget)}";
    }
    return "Low <${unitStr(TargetSettings().lowTarget)}";
  }

  @override
  String statment() {
    if (_lowTrigger()) {
      return "Low";
    }
    if (_predictiveTrigger()) {
      return "Predicted Low";
    }
    return "Low";
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
  String get title => "High Alarm";

  @override
  String get description {
    var unit = UISettings().unit;
    String description = "Alarm Above ${unit.str(TargetSettings().highTarget)}";
    if (AlarmSettings().highMinutes > 0) {
      description += " for ${AlarmSettings().highMinutes}m";
    }
    if (AlarmAlertSettings().smartSnoozeHigh) {
      description += " (w/ Smart Snooze)";
    }
    if (!AlarmSettings().highAlarm) {
      description = "Off";
    }
    return description;
  }

  @override
  String shortSummary() {
    if (smartSnooze()) {
      return "High <${unitStr(TargetSettings().highTarget)} Smart Snooze";
    }
    return "High >${unitStr(TargetSettings().highTarget)}";
  }

  @override
  String statment() {
    if (smartSnooze()) {
      return "High (Smart Snooze)";
    }
    return "High";
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
    List<Range5> targets = targetRange5s;
    if (targets.isEmpty) {
      // If targets is empty then we will have to wait for NoDataAlarm to trigger
      return false;
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
  String get title => "Urgent High Alarm";

  @override
  IconData icon() => UniconsLine.temperature_plus;

  @override
  String get description {
    var unit = UISettings().unit;
    String description = "Alarm Above ${unit.str(TargetSettings().highUrgent)}";
    if (!AlarmSettings().urgentHighAlarm) {
      description = "Off";
    }
    return description;
  }

  @override
  String shortSummary() => "Urgent High >${unitStr(TargetSettings().highUrgent)}";

  @override
  String statment() => "Urgent High";

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
  String get title => "Fast Rise Alarm";

  @override
  IconData icon() => UniconsLine.angle_double_up;

  @override
  String get description {
    var description = "Fast Rise Alarm ${unitStr(TargetSettings().fastRiseDelta)} for ${AlarmSettings().fastRiseAlarmMinutes}m";
    if (AlarmSettings().fastRiseAlarmMinutes < 0) {
      description = "Off";
    }
    return description;
  }

  @override
  String shortSummary() => "Fast Rise <${unitStr(TargetSettings().fastRiseDelta)}";

  @override
  String statment() => "Fast Rise";

  @override
  int get minutesToTrigger => AlarmSettings().fastRiseAlarmMinutes;

  @override
  bool trigger() {
    // Dont trigger if low or Very Low, fast rise when low is what we want
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
  String get title => "Fast Drop Alarm";

  @override
  IconData icon() => UniconsLine.angle_double_down;

  @override
  String get description {
    var description = "Fast Drop Alarm ${unitStr(TargetSettings().fastDropDelta)} for ${AlarmSettings().fastDropAlarmMinutes}m";
    if (AlarmSettings().fastDropAlarmMinutes < 0) {
      description = "Off";
    }
    return description;
  }

  @override
  String shortSummary() => "Fast Drop <${unitStr(TargetSettings().fastDropDelta)}";

  @override
  String statment() => "Fast Drop";

  @override
  int get minutesToTrigger => AlarmSettings().fastDropAlarmMinutes;

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
  String get title => "No Data Alarm";

  @override
  IconData icon() => UniconsLine.x;

  @override
  String get description {
    var description = "No Data Alarm after ${AlarmSettings().noDataAlarmMinutes}m";
    if (AlarmSettings().noDataAlarmMinutes < 0) {
      description = "Off";
    }
    return description;
  }

  @override
  String shortSummary() => "No Data for ${ageInMinutes ?? "unknown"}m";

  @override
  String statment() => "No Data";

  @override
  int get minutesToTrigger => AlarmSettings().noDataAlarmMinutes;

  @override
  bool trigger() {
    if (AlarmSettings().noDataAlarmMinutes <= 1) {
      return false;
    }

    int? age = ageInMinutes;
    if (age == null) {
      // We dont know how old, must have at least 1 in the last couple days to trigger
      return false;
    }

    return age > minutesToTrigger;
  }

  int? get ageInMinutes {
    var last2days = SGV.last2Days.value;
    var lastSGV = last2days.firstOrNull;
    if (lastSGV == null) {
      return null;
    }

    return lastSGV.age.inMinutes;
  }

  @override
  bool active() {
    return AlarmSettings().noDataAlarmMinutes > 0;
  }
}

class _LowBatteryAlarm extends AlarmMethods {
  const _LowBatteryAlarm();

  @override
  String get title => "Low Battery Alarm";

  @override
  IconData icon() => UniconsLine.battery_empty;

  @override
  Map<String, dynamic> details() {
    return super.details()
      ..addAll({
        "thisCharging": PlatformInfoService().thisPhoneIsCharging(),
        "thisBattery": PlatformInfoService().thisPhonesBatteryLevel(),
        "t1dCharging": PropertiesData().t1dPhoneIsCharging(),
        "t1dBattery": PropertiesData().t1dPhonesBatteryLevel(),
      });
  }

  @override
  String get description {
    String description = "Battery below 10%(";
    List<String> phones = [];
    if (AlarmSettings().t1dBatteryAlarm) {
      phones.add("T1D Phone");
    }
    if (AlarmSettings().carerBatteryAlarm) {
      phones.add("This Device");
    }
    description += "${phones.join(", ")})";

    if (!AlarmSettings().t1dBatteryAlarm && !AlarmSettings().carerBatteryAlarm) {
      description = "Off";
    }
    return description;
  }

  @override
  String shortSummary() {
    var statusStr = [];
    if (_carerTrigger()) {
      statusStr.add("Battery");
    }
    if (_t1DTrigger()) {
      statusStr.add("T1D Battery(${PropertiesData().t1dPhonesBatteryLevel()}%)");
    }

    return "${statusStr.join(" and ")} < 10%";
  }

  @override
  String statment() {
    var statusStr = [];
    if (_carerTrigger()) {
      statusStr.add("Battery");
    }
    if (_t1DTrigger()) {
      statusStr.add("T1D Battery");
    }
    return "${statusStr.join(" and ")} Low";
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
