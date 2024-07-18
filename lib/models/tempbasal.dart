import 'package:carer/models/model.dart';
import 'package:carer/sql/statements/carer_db_tables.dart';
import 'package:clock/clock.dart';
import 'package:signals/signals_flutter.dart';

class TempBasalRepository extends ModelRepository<TempBasal> {
  TempBasalRepository() : super(tempbasalTableName, timestampField: "start");

  @override
  TempBasal fromMap(Map<String, Object?> map) {
    var requiredKeys = ["start", "duration", "value", "eid"];
    if (!(validateNotNull(map, requiredKeys) &&
        validateType(map, [
          ("start", int),
          ("duration", int),
          ("value", int),
          ("eid", String),
        ]))) {
      throw ArgumentError("Invalid TempBasal Map: $map");
    }

    return TempBasal(
      id: map["id"] as int?,
      eid: map["eid"] as String,
      startDate: DateTime.fromMillisecondsSinceEpoch(map["start"] as int),
      duration: map["duration"] as int,
      value: map["value"] as double,
    );
  }

  @override
  Map<String, Object> toSQLMap(TempBasal model) {
    return {
      "start": model.startDate.millisecondsSinceEpoch,
      "duration": model.duration,
      "value": model.value,
      "eid": model.eid!,
    };
  }
}

class TempBasal extends Model {
  static final TempBasalRepository _q = TempBasalRepository();

  @override
  ModelRepository get repository => _q;

  @override
  get date => startDate;

  final DateTime startDate;
  final int duration;
  final double value;

  TempBasal({
    super.id,
    required super.eid,
    required this.startDate,
    required this.duration,
    required this.value,
  });

  DateTime get dateEnd {
    return startDate.add(Duration(seconds: duration));
  }

  Duration get remaining {
    return dateEnd.difference(clock.now());
  }

  factory TempBasal.fromMap(Map<String, dynamic> map) {
    return _q.fromMap(map);
  }

  static Future<List<TempBasal>> query({int? after, int? before, int? limit}) async {
    return _q.query(after: after, before: before, limit: limit);
  }

  static Future<TempBasal?> atTime(DateTime date) async {
    var ms = date.millisecondsSinceEpoch;
    return (await _q.query(conditions: {"start <= ?": ms, "end >= ?": ms}, limit: 1)).firstOrNull;
  }

  static Future<int> saveAll(List<TempBasal> models) => _q.saveAll(models);
  static Future<int> upsertAll(List<TempBasal> models) => _q.upsertAll(models);

  static Signal<int> get writeSignal => _q.writeSignal;
}
