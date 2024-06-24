import 'package:carer/models/model.dart';
import 'package:carer/models/profile.dart';
import 'package:carer/models/tempbasal.dart';
import 'package:carer/models/temptarget.dart';
import 'package:carer/sql/statements/carer_db_tables.dart';
import 'package:clock/clock.dart';
import 'package:signals/signals_flutter.dart';

class ValueAtTimeRepository extends ModelRepository<ValueAtTime> {
  ValueAtTimeRepository() : super(valuesAtTimeViewName);

  @override
  ValueAtTime fromMap(Map<String, Object?> map) {
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

    return ValueAtTime(
      date: DateTime.fromMillisecondsSinceEpoch(map["timestamp"] as int),
      targetLow: map["targetLow"] as int,
      targetHigh: map["targetHigh"] as int,
      basal: map["basal"] as double,
      isTempBasal: map["isTempBasal"] == 1,
      isTempTarget: map["isTempTarget"] == 1,
    );
  }

  @override
  Map<String, Object> toSQLMap(ValueAtTime model) {
    return {
      "timestamp": model.date.millisecondsSinceEpoch,
      "targetLow": model.targetLow,
      "targetHigh": model.targetHigh,
      "isTempTarget": model.isTempTarget ? 1 : 0,
    };
  }
}

class ValueAtTime extends Model {
  static final ValueAtTimeRepository _q = ValueAtTimeRepository();

  @override
  ModelRepository get repository => _q;

  @override
  get id => null; // This is a view
  @override
  set id(_) {}

  @override
  final DateTime date;

  final int targetLow;
  final int targetHigh;
  final bool isTempTarget;
  final double basal;
  final bool isTempBasal;

  ValueAtTime(
      {required this.date,
      required this.targetLow,
      required this.targetHigh,
      required this.isTempTarget,
      required this.basal,
      required this.isTempBasal});

  factory ValueAtTime.fromMap(Map<String, dynamic> map) {
    return _q.fromMap(map);
  }

  int get minsAgo =>
      (clock.now().millisecondsSinceEpoch - date.millisecondsSinceEpoch) ~/
      60000;

  static Future<List<ValueAtTime>> query({
    int? after,
    int? before,
    Map<String, Object>? conditions,
    int? limit,
  }) {
    return _q.query(
        before: before, after: after, limit: limit, conditions: conditions);
  }

  static Future<List<ValueAtTime>> lastMins(int minsAgo) =>
      _q.lastMins(minsAgo);

  static FutureSignal<List<ValueAtTime>> lastSixHours = computedAsync(() async {
    print("updating Treatments lastSixHours");
    var b = TempTarget.writeSignal.value;
    var c = TempBasal.writeSignal.value;
    var d = Profile.writeSignal.value;
    return await ValueAtTime.lastMins(60 * 6);
  }, initialValue: [], debugLabel: 'treatmentsLastSixHours');
}
