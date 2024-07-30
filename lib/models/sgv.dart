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

  static FutureSignal<double?> todaysPercentage = acomputedAsync(() async {
    var _ = SQLToSGV().writeSignal.value; // force update on save
    var (value, err) = await go(_percentInRangeToday(TargetSettings().lowTarget, TargetSettings().highTarget));
    if (err != null || value == null) {
      alog("Error todaysPercentage: $err");
      return 0.0;
    }
    alog("updated todaysPercentage");
    return value * 100.0;
  }, 0.0, debugLabel: 'todaysPercentage');

  static FutureSignal<double?> yesterdaysPercentage = acomputedAsync(() async {
    alog("updating yesterdaysPercentage");
    var _ = SQLToSGV().writeSignal.value; // force update on save

    var (value, err) = await go(_percentInRangeYesterday(TargetSettings().lowTarget, TargetSettings().highTarget));

    if (err != null || value == null) {
      alog("Error yesterdaysPercentage: $err");
      return 0.0;
    }
    alog("updated yesterdaysPercentage Signal");
    return value * 100.0;
  }, 0.0, debugLabel: 'yesterdaysPercentage');

  static Signal<CleanSGV?> lastSGV = Signal(null, debugLabel: 'lastSGV');

  static FutureSignal<List<CleanSGV>> last3Hours = acomputedAsync(() async {
    alog("updating last3Hours");
    var _ = SQLToSGV().writeSignal.value; // force update on save

    var ret = await SQLToCleanSGV().lastMins(60 * 3);
    alog("updated last3Hours Signal");
    return ret;
  }, [], debugLabel: 'last3Hours');

  static setupSQLSignals() {
    //acomputedAsync will set the value of the signal to null while computing
    // This makes the app blink a bunch
    aeffect(() async {
      var sgv = await SQLToCleanSGV().query(limit: 1, name: "lastSGVQuery").then((value) => value.firstOrNull);
      untracked(() {
        lastSGV.value = sgv;
      });

      return null;
    }, debugLabel: 'lastSGVQuery', dependencies: [SQLToSGV().writeSignal]);
  }
}
