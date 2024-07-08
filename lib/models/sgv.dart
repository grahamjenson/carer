import 'package:carer/models/constants.dart';
import 'package:carer/models/model.dart';
import 'package:carer/services/settings/target_settings.dart';
import 'package:carer/sql/statements/carer_db_tables.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/utils/logs.dart';
import 'package:clock/clock.dart';
import 'package:signals/signals_flutter.dart';

class SGVRepository extends ModelRepository<SGV> {
  SGVRepository() : super(sgvsCleanViewTableName, writeTableName: sgvsTableName);

  @override
  SGV fromMap(Map<String, Object?> map) {
    var requiredKeys = ["value", "timestamp", "eid"];
    if (!(validateNotNull(map, requiredKeys) && validateType(map, requiredKeys, [int, int, String]))) {
      throw ArgumentError("Invalid SVG Map: $map");
    }

    return SGV(
      id: map["id"] as int?,
      eid: map["eid"] as String,
      value: map["value"] as int,
      date: DateTime.fromMillisecondsSinceEpoch(map["timestamp"] as int),
      rate5m: map["rate5m"] as int?,
      diff: map["diff"] as int?,
      idBefore: map["id_before"] as int?,
    );
  }

  @override
  Map<String, Object> toSQLMap(SGV model) {
    return {
      "value": model.value,
      "timestamp": model.date.millisecondsSinceEpoch,
      "eid": model.eid!,
    };
  }
}

class SGV extends Model {
  static final SGVRepository _q = SGVRepository();

  @override
  ModelRepository get repository => _q;

  final int value;

  @override
  final DateTime date;
  int? rate5m;
  int? diff;
  int? idBefore; // previous SVGs ID

  SGV({
    required this.value,
    required this.date,
    required super.eid,
    super.id,
    this.rate5m,
    this.diff,
    this.idBefore,
  });

  factory SGV.fromMap(Map<String, Object?> map) {
    return _q.fromMap(map);
  }

  int get minsAgo => (clock.now().millisecondsSinceEpoch - date.millisecondsSinceEpoch) ~/ 60000;
  int get minsFromNow => (date.millisecondsSinceEpoch - clock.now().millisecondsSinceEpoch) ~/ 60000;

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
    return _q.count(after: after, before: before, conditions: conditions);
  }

  static Future<List<SGV>> query({int? after, int? before, int? low, int? high, int? limit, String? name}) async {
    var conditions = <String, Object>{};
    if (low != null) {
      conditions["value >= ?"] = low;
    }
    if (high != null) {
      conditions["value < ?"] = high;
    }

    return _q.query(after: after, before: before, conditions: conditions, limit: limit, name: name, orderBy: "timestamp DESC, value");
  }

  static Future<List<SGV>> lastMins(int minsAgo) => _q.lastMins(minsAgo);

  static Future<double> _percentInRangeToday(int low, int high) async {
    DateTime now = clock.now();
    DateTime startOfDay = DateTime(now.year, now.month, now.day);
    int startOfDayEpoch = startOfDay.millisecondsSinceEpoch;

    var sgvsTodayInRange = await _q.count(
      after: startOfDayEpoch,
      conditions: {"value >= ?": low, "value < ?": high},
    );

    var sgvsToday = await _q.count(after: startOfDayEpoch);
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

    var sgvsTodayInRange = await _q.count(
      after: startOfYesterdayEpoch,
      before: startOfDayEpoch,
      conditions: {"value >= ?": low, "value < ?": high},
    );

    var sgvsToday = await _q.count(after: startOfYesterdayEpoch, before: startOfDayEpoch);

    if (sgvsTodayInRange == null || sgvsToday == null || sgvsToday == 0) {
      return 0.0;
    }

    return sgvsTodayInRange / sgvsToday;
  }

  static Future<int> saveAll(List<SGV> sgvs) => _q.saveAll(sgvs);

  ////
  // SIGNALS
  ////

  static FutureSignal<double?> todaysPercentage = acomputedAsync(() async {
    var _ = writeSignal.value; // force update on save
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
    var _ = writeSignal.value; // force update on save

    var (value, err) = await go(_percentInRangeYesterday(TargetSettings().lowTarget, TargetSettings().highTarget));

    if (err != null || value == null) {
      alog("Error yesterdaysPercentage: $err");
      return 0.0;
    }
    alog("updated yesterdaysPercentage Signal");
    return value * 100.0;
  }, 0.0, debugLabel: 'yesterdaysPercentage');

  static FutureSignal<SGV?> lastSGV = acomputedAsync(() async {
    alog("updating LastSGV");
    var _ = writeSignal.value; // force update on save

    var ret = await _q.query(limit: 1, name: "lastSGV").then((value) => value.firstOrNull);
    alog("updated LastSGV Signal");
    return ret;
  }, null, debugLabel: 'LastSGV');

  static FutureSignal<List<SGV>> last3Hours = acomputedAsync(() async {
    alog("updating last3Hours");
    var _ = writeSignal.value; // force update on save

    var ret = await SGV.lastMins(60 * 3);
    alog("updated last3Hours Signal");
    return ret;
  }, [], debugLabel: 'last3Hours');

  static Signal<int> get writeSignal => _q.writeSignal;
}
