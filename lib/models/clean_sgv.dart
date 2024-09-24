import 'package:carer/mappers/sql_mappers.dart';
import 'package:carer/models/model.dart';
import 'package:carer/models/sql/constants.dart';
import 'package:carer/models/sql/sgv.dart';
import 'package:carer/services/settings/target_settings.dart';
import 'package:carer/utils/futures.dart';
import 'package:clock/clock.dart';

class CleanSGV with DateMixin {
  final int value;

  @override
  final DateTime date;

  CleanSGV? before; // previous SVGs ID

  CleanSGV(
    this.value,
    this.date, {
    this.before,
  });

  int? get rate5m {
    if (before == null) {
      return null;
    }
    return ((diff! / (minuteTimestamp - before!.minuteTimestamp)) * 5).toInt();
  }

  int? get diff {
    if (before == null) {
      return null;
    }
    return value - before!.value;
  }

  double sgvU(Unit unit) {
    return unit.val(value);
  }

  String sgvStr(Unit unit) {
    switch (unit) {
      case Unit.mg:
        return value.toString();
      case Unit.mmol:
        return (value / MGtoMMOL).toStringAsFixed(1);
    }
  }

  String rate5mWithSign(Unit unit) {
    var diffPer5Mins = rate5m ?? 0;
    var sgv = unit.val(diffPer5Mins);
    var sgvStr = sgv.toStringAsFixed(1);
    if (sgv == 0) {
      sgvStr = "+0";
    } else if (sgv > 0) {
      sgvStr = "+${sgv.toStringAsFixed(1)}";
    }
    return sgvStr;
  }

  @override
  String toString() {
    return "SGV($value@${date.hour}:${date.minute})";
  }

  bool get withinLast3Hours => date.isAfter(clock.now().subtract(const Duration(hours: 3)));

  bool get withinRange => value > TargetSettings().lowTarget && value < TargetSettings().highTarget;

  static List<CleanSGV> _makeChained(List<CleanSGV> sgvs) {
    if (sgvs.isEmpty || sgvs.length == 1) {
      return sgvs;
    }

    List<CleanSGV> chainedSGVs = [sgvs.first];

    var dateBefore = sgvs.first.date;
    for (var i = 1; i < sgvs.length; i++) {
      var sgv = sgvs[i];

      if (dateBefore.difference(sgv.date).inMinutes > 3) {
        chainedSGVs.last.before = sgv;
        dateBefore = sgv.date;
        chainedSGVs.add(sgv);
      }
    }

    return chainedSGVs;
  }

  static int count() {
    return last2Days.value.length;
  }

  // This is the root signal that caches and filters all SGVs from the last two days
  static ASignal<List<CleanSGV>> last2Days = ASignal([], debugLabel: 'last2Days');

  static ASignal<List<CleanSGV>> last3Hours = ASignal([], debugLabel: 'lastSGV3Hours');

  static ASignal<CleanSGV?> lastSGV = ASignal(null, debugLabel: 'lastSGV');

  static ASignal<double?> todaysPercentage = ASignal(0.0, debugLabel: 'todaysPercentage');
  static ASignal<double?> yesterdaysPercentage = ASignal(0.0, debugLabel: 'yesterdaysPercentage');

  static setupSQLSignals() {
    signalAssign(last2Days, () async {
      DateTime now = clock.now();
      DateTime startOfYesterday = DateTime(now.year, now.month, now.day - 1);
      int startOfYesterdayEpoch = startOfYesterday.millisecondsSinceEpoch;

      List<SGV> rawSGVs = await SQLToSGV().query(after: startOfYesterdayEpoch);

      return _makeChained(rawSGVs.map((e) => CleanSGV(e.value, e.date)).toList());
    }, debugLabel: "last2DaysQuery", dependencies: [SQLToSGV().writeSignal]);

    signalAssign(last3Hours, () => last2Days.value.where((e) => e.withinLast3Hours).toList(), debugLabel: 'last3HoursQuery');

    signalAssign(lastSGV, () => last2Days.value.firstOrNull, debugLabel: 'lastSGVQuery');

    signalAssign(todaysPercentage, () {
      var todaysSGVs = last2Days.value.where((e) => e.isDuringToday);
      var todaysSGVsInRange = todaysSGVs.where((e) => e.withinRange);

      return todaysSGVs.isEmpty ? 0.0 : (todaysSGVsInRange.length / todaysSGVs.length) * 100.0;
    }, debugLabel: 'todaysPercentage', dependencies: [last2Days]);

    signalAssign(yesterdaysPercentage, () {
      var yesterdaysSGVs = last2Days.value.where((e) => e.isDuringYesterday);
      var yesterdaysSGVsInRange = yesterdaysSGVs.where((e) => e.withinRange);

      return yesterdaysSGVs.isEmpty ? 0.0 : (yesterdaysSGVsInRange.length / yesterdaysSGVs.length) * 100.0;
    }, debugLabel: 'yesterdaysPercentage', dependencies: [last2Days]);
  }
}
