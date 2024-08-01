import 'package:carer/mappers/sql_mappers.dart';
import 'package:carer/models/constants.dart';
import 'package:carer/models/model.dart';
import 'package:carer/services/settings/target_settings.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/utils/logs.dart';
import 'package:clock/clock.dart';
import 'package:signals/signals_flutter.dart';

class SGV extends Model {
  final int value;

  @override
  final DateTime date;

  SGV({
    required this.value,
    required this.date,
    required super.eid,
    super.id,
  });
}

class CleanSGV extends Model {
  final int value;

  @override
  final DateTime date;
  int? rate5m;
  int? diff;
  int? idBefore; // previous SVGs ID

  CleanSGV({
    super.id,
    required this.value,
    required this.date,
    required super.eid,
    this.rate5m,
    this.diff,
    this.idBefore,
  });

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
    return "SGV: $value@${date.hour}:${date.minute}";
  }

  // STATIC FUNCTIONS
  static Future<int?> count({int? after, int? before, int? low, int? high}) async {
    var conditions = <String, Object>{};
    if (low != null) {
      conditions["value >= ?"] = low;
    }
    if (high != null) {
      conditions["value < ?"] = high;
    }
    return SQLToCleanSGV().count(after: after, before: before, conditions: conditions);
  }

  static Future<List<CleanSGV>> query({int? after, int? before, int? low, int? high, int? limit, String? name}) async {
    var conditions = <String, Object>{};
    if (low != null) {
      conditions["value >= ?"] = low;
    }
    if (high != null) {
      conditions["value < ?"] = high;
    }

    return SQLToCleanSGV().query(after: after, before: before, conditions: conditions, limit: limit, name: name, orderBy: "timestamp DESC, value");
  }

  static Future<List<CleanSGV>> lastMins(int minsAgo) => SQLToCleanSGV().lastMins(minsAgo);

  static Future<double> _percentInRangeToday(int low, int high) async {
    DateTime now = clock.now();
    DateTime startOfDay = DateTime(now.year, now.month, now.day);
    int startOfDayEpoch = startOfDay.millisecondsSinceEpoch;

    var sgvsTodayInRange = await SQLToCleanSGV().count(
      after: startOfDayEpoch,
      conditions: {"value >= ?": low, "value < ?": high},
    );

    var sgvsToday = await SQLToCleanSGV().count(after: startOfDayEpoch);
    if (sgvsTodayInRange == null || sgvsToday == null || sgvsToday == 0) {
      return 0.0;
    }

    return sgvsTodayInRange / sgvsToday;
  }

  static Future<double> _percentInRangeYesterday(int low, int high) async {
    DateTime now = clock.now();
    DateTime startOfDay = DateTime(now.year, now.month, now.day);
    int startOfDayEpoch = startOfDay.millisecondsSinceEpoch;

    DateTime startOfYesterday = DateTime(now.year, now.month, now.day - 1);
    int startOfYesterdayEpoch = startOfYesterday.millisecondsSinceEpoch;

    var sgvsTodayInRange = await SQLToCleanSGV().count(
      after: startOfYesterdayEpoch,
      before: startOfDayEpoch,
      conditions: {"value >= ?": low, "value < ?": high},
    );

    var sgvsToday = await SQLToCleanSGV().count(after: startOfYesterdayEpoch, before: startOfDayEpoch);

    if (sgvsTodayInRange == null || sgvsToday == null || sgvsToday == 0) {
      return 0.0;
    }

    return sgvsTodayInRange / sgvsToday;
  }

  // TODO fix this up somehow and TEST IT
  // This method returns all the last3Hour of SGVs, but chained together with their before values
  static List<CleanSGV> last3HoursChained() {
    List<CleanSGV> sgvs = CleanSGV.last3Hours.value;
    if (sgvs.isEmpty) {
      return [];
    }
    List<CleanSGV> chainedSGVs = [sgvs.first];
    // Get the first id before

    var idBefore = sgvs.first.idBefore;
    for (var i = 1; i < sgvs.length; i++) {
      var sgv = sgvs[i];
      if (sgv.id != idBefore) {
      } else {
        idBefore = sgv.idBefore;
        chainedSGVs.add(sgv);
      }
    }
    return chainedSGVs;
  }

  static Signal<CleanSGV?> lastSGV = Signal(null, debugLabel: 'lastSGV');
  static Signal<List<CleanSGV>> last3Hours = Signal([], debugLabel: 'lastSGV');
  static Signal<double?> yesterdaysPercentage = Signal(0.0, debugLabel: 'yesterdaysPercentage');
  static Signal<double?> todaysPercentage = Signal(0.0, debugLabel: 'todaysPercentage');

  static setupSQLSignals() {
    signalAssign(lastSGV, () => SQLToCleanSGV().query(limit: 1, name: "lastSGVQuery").then((value) => value.firstOrNull),
        debugLabel: 'lastSGVQuery', dependencies: [SQLToSGV().writeSignal]);

    signalAssign(last3Hours, () => SQLToCleanSGV().lastMins(60 * 3), debugLabel: 'last3HoursQuery', dependencies: [SQLToSGV().writeSignal]);

    signalAssign(yesterdaysPercentage, () async {
      var (value, err) = await go(_percentInRangeYesterday(TargetSettings().lowTarget, TargetSettings().highTarget));

      if (err != null || value == null) {
        alog("Error yesterdaysPercentage: $err");
        return 0.0;
      }
      alog("updated yesterdaysPercentage Signal");
      return value * 100.0;
    }, debugLabel: 'yesterdaysPercentage', dependencies: [SQLToSGV().writeSignal]);

    signalAssign(todaysPercentage, () async {
      var (value, err) = await go(_percentInRangeToday(TargetSettings().lowTarget, TargetSettings().highTarget));
      if (err != null || value == null) {
        alog("Error todaysPercentage: $err");
        return 0.0;
      }
      alog("updated todaysPercentage");
      return value * 100.0;
    }, debugLabel: 'todaysPercentage', dependencies: [SQLToSGV().writeSignal]);
  }
}
