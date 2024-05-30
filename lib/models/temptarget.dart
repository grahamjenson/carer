import 'package:carer/models/model.dart';
import 'package:carer/sql/statements/carer_db_tables.dart';
import 'package:clock/clock.dart';

class TempTargetRepository extends ModelRepository<TempTarget> {
  const TempTargetRepository()
      : super(temptargetsTableName, timestampField: "start");

  @override
  TempTarget fromMap(Map<String, Object?> map) {
    var requiredKeys = ["start", "duration", "targetTop", "targetBottom"];
    if (!(validateNotNull(map, requiredKeys) &&
        validateType(map, requiredKeys, [int, int, int, int]))) {
      throw ArgumentError("Invalid SVG Map: $map");
    }

    return TempTarget(
      id: map["id"] as int?,
      startDate: DateTime.fromMillisecondsSinceEpoch(map["start"] as int),
      duration: map["duration"] as int,
      targetTop: map["targetTop"] as int,
      targetBottom: map["targetBottom"] as int,
    );
  }

  @override
  Map<String, Object> toSQLMap(TempTarget model) {
    return {
      "start": model.startDate.millisecondsSinceEpoch,
      "duration": model.duration,
      "targetTop": model.targetTop,
      "targetBottom": model.targetBottom,
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
  final int targetTop;
  final int targetBottom;

  TempTarget({
    this.id,
    required this.startDate,
    required this.duration,
    required this.targetTop,
    required this.targetBottom,
  });

  DateTime get dateEnd {
    return startDate.add(Duration(seconds: duration));
  }

  Duration get remaining {
    return dateEnd.difference(clock.now());
  }

  factory TempTarget.fromMap(Map<String, dynamic> map) {
    return _q.fromMap(map);
  }
}
