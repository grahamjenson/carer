import 'package:carer/models/model.dart';
import 'package:carer/sql/statements/carer_db_tables.dart';

class TargetRepository extends ModelRepository<Target> {
  const TargetRepository() : super(targetAtTimeViewName);

  @override
  Target fromMap(Map<String, Object?> map) {
    var requiredKeys = [
      "timestamp",
      "targetLow",
      "targetHigh",
      "isTempTarget",
      "basal",
      "isTempBasal"
    ];
    if (!(validateNotNull(map, requiredKeys) &&
        validateType(map, requiredKeys, [int, int, int, int, double, int]))) {
      throw ArgumentError("Invalid Target Map: $map");
    }

    return Target(
      date: DateTime.fromMillisecondsSinceEpoch(map["timestamp"] as int),
      targetLow: map["targetLow"] as int,
      targetHigh: map["targetHigh"] as int,
      basal: map["basal"] as double,
      isTempBasal: map["isTempBasal"] == 1,
      isTempTarget: map["isTempTarget"] == 1,
    );
  }

  @override
  Map<String, Object> toSQLMap(Target model) {
    return {
      "timestamp": model.date.millisecondsSinceEpoch,
      "targetLow": model.targetLow,
      "targetHigh": model.targetHigh,
      "isTempTarget": model.isTempTarget ? 1 : 0,
    };
  }
}

class Target extends Model {
  static const TargetRepository _q = TargetRepository();

  @override
  ModelRepository get repository => _q;

  @override
  get id => null; // This is a view

  @override
  final DateTime date;

  final int targetLow;
  final int targetHigh;
  final bool isTempTarget;
  final double basal;
  final bool isTempBasal;

  Target(
      {required this.date,
      required this.targetLow,
      required this.targetHigh,
      required this.isTempTarget,
      required this.basal,
      required this.isTempBasal});

  factory Target.fromMap(Map<String, dynamic> map) {
    return _q.fromMap(map);
  }

  static Future<List<Target>> query({
    int? after,
    int? before,
    Map<String, Object>? conditions,
    int? limit,
  }) async {
    Stopwatch stopwatch = Stopwatch()..start();
    var ret = await _q.query(
        before: before, after: after, limit: limit, conditions: conditions);
    stopwatch.stop();

    print('TARGET STUFF executed in ${stopwatch.elapsed.inMilliseconds}');

    return ret;
  }
}
