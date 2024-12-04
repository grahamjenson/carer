import 'package:carer/mappers/sql/sgv.dart';
import 'package:carer/models/sql/db_model.dart';
import 'package:carer/services/settings/target_settings.dart';
import 'package:carer/services/settings/ui_settings.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/utils/math.dart';

abstract class ASGV {
  int get value;
  DateTime get date;
  Range5 get range;
  bool get isUrgentLow;
  bool get isLow;
  bool get isNormal;
  bool get isHigh;
  bool get isUrgentHigh;

  int get minsAgo;
  Duration get age;
  String sgvStr();

  String unitStr() {
    return UISettings().unit.str(value);
  }

  // Override equals if same value and date it is the same
  @override
  bool operator ==(Object other) {
    if (other is ASGV) {
      return other.value == value && other.date == date;
    }
    return false;
  }

  @override
  int get hashCode => value.hashCode ^ date.hashCode;
}

class SGV extends DBModel implements ASGV {
  @override
  final int value;

  @override
  final DateTime date;

  SGV({
    required this.value,
    required this.date,
    required super.eid,
    super.id,
  });

  @override
  Range5 get range => targetRange(value);

  @override
  bool get isUrgentLow => range == Range5.veryLow;
  @override
  bool get isLow => range == Range5.low;
  @override
  bool get isNormal => range == Range5.mid;
  @override
  bool get isHigh => range == Range5.high;
  @override
  bool get isUrgentHigh => range == Range5.veryHigh;

  @override
  String sgvStr() {
    return UISettings().unit.str(value);
  }

  @override
  String toString() {
    return "SGV($value@${date.hour}:${date.minute})";
  }

  bool get withinRange => value > TargetSettings().lowTarget && value < TargetSettings().highTarget;

  static int count() {
    return last2Days.value.length;
  }

  static ASignal<List<SGV>> last2Days = ASignal<List<SGV>>([], debugLabel: "SGVLast2Days");

  static ASignal<double?> todaysPercentage = ASignal(0.0, debugLabel: 'todaysPercentage');
  static ASignal<double?> yesterdaysPercentage = ASignal(0.0, debugLabel: 'yesterdaysPercentage');

  static Future<void> setupSQLSignals() async {
    await signalAssign(last2Days, () async => SQLToSGV().last2Days(), debugLabel: "SGVlast2Days", dependencies: [SQLToSGV().writeSignal]);

    await signalAssign(todaysPercentage, () {
      var todaysSGVs = last2Days.value.where((e) => e.isDuringToday);
      var todaysSGVsInRange = todaysSGVs.where((e) => e.withinRange);

      return todaysSGVs.isEmpty ? 0.0 : (todaysSGVsInRange.length / todaysSGVs.length) * 100.0;
    }, debugLabel: 'writeTodaysPercentage', dependencies: [last2Days]);

    await signalAssign(yesterdaysPercentage, () {
      var yesterdaysSGVs = last2Days.value.where((e) => e.isDuringYesterday);
      var yesterdaysSGVsInRange = yesterdaysSGVs.where((e) => e.withinRange);

      return yesterdaysSGVs.isEmpty ? 0.0 : (yesterdaysSGVsInRange.length / yesterdaysSGVs.length) * 100.0;
    }, debugLabel: 'writeYesterdaysPercentage', dependencies: [last2Days]);
  }

  @override
  String unitStr() {
    return UISettings().unit.str(value);
  }
}
