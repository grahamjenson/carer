import 'package:carer/models/model.dart';
import 'package:carer/sql/statements/carer_db_tables.dart';
import 'package:clock/clock.dart';

class TempTargetRepository extends ModelRepository<TempTarget> {
  const TempTargetRepository()
      : super(temptargetsTableName, timestampField: "start");

  @override
  TempTarget fromMap(Map<String, Object?> map) {
    var requiredKeys = ["start", "duration", "targetHigh", "targetLow"];
    if (!(validateNotNull(map, requiredKeys) &&
        validateType(map, requiredKeys, [int, int, int, int]))) {
      throw ArgumentError("Invalid SVG Map: $map");
    }

    return TempTarget(
      id: map["id"] as int?,
      startDate: DateTime.fromMillisecondsSinceEpoch(map["start"] as int),
      duration: map["duration"] as int,
      targetHigh: map["targetHigh"] as int,
      targetLow: map["targetLow"] as int,
    );
  }

  @override
  Map<String, Object> toSQLMap(TempTarget model) {
    return {
      "start": model.startDate.millisecondsSinceEpoch,
      "duration": model.duration,
      "targetHigh": model.targetHigh,
      "targetLow": model.targetLow,
    };
  }
}

class TempTarget extends Model {
  static const TempTargetRepository _q = TempTargetRepository();

  @override
  ModelRepository get repository => _q;

  @override
  final int? id;

  @override
  get date => startDate;

  final DateTime startDate;
  final int duration;
  final int targetLow;
  final int targetHigh;

  TempTarget({
    this.id,
    required this.startDate,
    required this.duration,
    required this.targetLow,
    required this.targetHigh,
  });

  @override
  List<String> uniqueValues() {
    return ["start"];
  }

  DateTime get dateEnd {
    return startDate.add(Duration(seconds: duration));
  }

  Duration get remaining {
    return dateEnd.difference(clock.now());
  }

  factory TempTarget.fromMap(Map<String, dynamic> map) {
    return _q.fromMap(map);
  }

  static Future<List<TempTarget>> query(
      {int? after, int? before, int? limit}) async {
    return _q.query(after: after, before: before, limit: limit);
  }

  static Future<TempTarget?> atTime(DateTime date) async {
    var ms = date.millisecondsSinceEpoch;
    return (await _q
            .query(conditions: {"start <= ?": ms, "end >= ?": ms}, limit: 1))
        .firstOrNull;
  }
}
