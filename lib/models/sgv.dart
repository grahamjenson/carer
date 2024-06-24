import 'package:carer/models/constants.dart';
import 'package:carer/models/model.dart';
import 'package:carer/signals/settings/target_settings.dart';
import 'package:carer/sql/statements/carer_db_tables.dart';
import 'package:clock/clock.dart';
import 'package:signals/signals_flutter.dart';

class SGVRepository extends ModelRepository<SGV> {
  const SGVRepository()
      : super(sgvsCleanViewTableName, writeTableName: sgvsTableName);

  @override
  SGV fromMap(Map<String, Object?> map) {
    var requiredKeys = ["value", "timestamp"];
    if (!(validateNotNull(map, requiredKeys) &&
        validateType(map, requiredKeys, [int, int]))) {
      throw ArgumentError("Invalid SVG Map: $map");
    }

    {
      return SGV(
        id: map["id"] as int?,
        value: map["value"] as int,
        date: DateTime.fromMillisecondsSinceEpoch(map["timestamp"] as int),
        rate5m: map["rate5m"] as int?,
        diff: map["diff"] as int?,
        idBefore: map["id_before"] as int?,
      );
    }
  }

  @override
  Map<String, Object> toSQLMap(SGV model) {
    return {
      "value": model.value,
      "timestamp": model.date.millisecondsSinceEpoch,
    };
  }
}

class SGV extends Model {
  static const SGVRepository _q = SGVRepository();

  @override
  ModelRepository get repository => _q;

  @override
  final int? id;
  final int value;

  @override
  final DateTime date;
  int? rate5m;
  int? diff;
  int? idBefore; // previous SVGs ID

  SGV({
    required this.value,
    required this.date,
    this.id,
    this.rate5m,
    this.diff,
    this.idBefore,
  });

  factory SGV.fromMap(Map<String, Object?> map) {
    return _q.fromMap(map);
  }

  int get minsAgo =>
      (clock.now().millisecondsSinceEpoch - date.millisecondsSinceEpoch) ~/
      60000;

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
  static Future<int?> count(
      {int? after, int? before, int? low, int? high}) async {
    var conditions = <String, Object>{};
    if (low != null) {
      conditions["value >= ?"] = low;
    }
    if (high != null) {
      conditions["value < ?"] = high;
    }
    return _q.count(after: after, before: before, conditions: conditions);
  }

  static Future<List<SGV>> query(
      {int? after,
      int? before,
      int? low,
      int? high,
      int? limit,
      String? name}) async {
    var conditions = <String, Object>{};
    if (low != null) {
      conditions["value >= ?"] = low;
    }
    if (high != null) {
      conditions["value < ?"] = high;
    }

    return _q.query(
        after: after,
        before: before,
        conditions: conditions,
        limit: limit,
        name: name);
  }

  // return the last sgvs for minutes'
  static Map<int, List<SGV>> lastMinsCache = {};

  static Future<List<SGV>> lastMins(int minsAgo) async {
    if (lastMinsCache[minsAgo] != null) {
      return lastMinsCache[minsAgo]!;
    }
    var ret = (await _q.lastMins(minsAgo));
    lastMinsCache[minsAgo] = ret;
    return ret;
  }

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

    var sgvsToday =
        await _q.count(after: startOfYesterdayEpoch, before: startOfDayEpoch);

    if (sgvsTodayInRange == null || sgvsToday == null || sgvsToday == 0) {
      return 0.0;
    }

    return sgvsTodayInRange / sgvsToday;
  }

  // overside save to cache lastMins and lastSGV values
  @override
  Future<bool> save() async {
    var ret = await super.save();
    if (ret) {
      lastMinsCache = {};
      SGV.sgvWriteSignal.value = clock.now().millisecondsSinceEpoch;
    }

    return ret;
  }

  static Future<int> saveAll(List<SGV> sgvs) async {
    var ret = await _q.saveAll(sgvs);

    if (ret > 0) {
      lastMinsCache = {};
      SGV.sgvWriteSignal.value = clock.now().millisecondsSinceEpoch;
    }

    return ret;
  }
  ////
  // SIGNALS
  ////

  static Signal<int> sgvWriteSignal = Signal(0, debugLabel: "SGVWrite");

  static FutureSignal<double?> todaysPercentage = computedAsync(() async {
    print("updating Future Signal todaysPercentage Signal");
    var _ = SGV.sgvWriteSignal.value; // force update on save
    try {
      var value = await _percentInRangeToday(
          TargetSettings().targetLow, TargetSettings().targetHigh);

      return value * 100.0;
    } catch (e, s) {
      print("Error todaysPercentage: $e");
      print("Stack todaysPercentage: $s");
      return 0.0;
    }
  }, initialValue: 0.0, debugLabel: 'todaysPercentage');

  static FutureSignal<double?> yesterdaysPercentage = computedAsync(() {
    print("updating Future Signal yesterdaysPercentage Signal");
    var _ = SGV.sgvWriteSignal.value; // force update on save
    return _percentInRangeYesterday(
            TargetSettings().targetLow, TargetSettings().targetHigh)
        .then((value) => value * 100.0);
  }, initialValue: 0.0, debugLabel: 'yesterdaysPercentage');

  static FutureSignal<SGV?> lastSGV = computedAsync(() {
    print("updating LastSGV Signal");
    var _ = SGV.sgvWriteSignal.value; // force update on save

    return _q
        .query(limit: 1, name: "lastSGV")
        .then((value) => value.firstOrNull);
  }, debugLabel: 'LastSGV');
}
