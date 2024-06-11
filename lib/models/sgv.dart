import 'package:carer/models/constants.dart';
import 'package:carer/models/model.dart';
import 'package:carer/sql/statements/carer_db_tables.dart';
import 'package:clock/clock.dart';

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

  Future<String> rate5mWithSign(Unit unit) async {
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

  static Future<SGV?> lastSGV() async {
    // TODO cache this for 5 mins (if becoms a problem)
    return (await _q.query(limit: 1)).firstOrNull;
  }

  static Future<List<SGV>> query(
      {int? after, int? before, int? low, int? high, int? limit}) async {
    var conditions = <String, Object>{};
    if (low != null) {
      conditions["value >= ?"] = low;
    }
    if (high != null) {
      conditions["value < ?"] = high;
    }

    return _q.query(
        after: after, before: before, conditions: conditions, limit: limit);
  }

  // return the last sgvs for minutes
  static Future<List<SGV>> lastMins(int minsAgo) async {
    return (await _q.lastMins(minsAgo));
  }

  static Future<double> percentInRangeToday(int low, int high) async {
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
}
