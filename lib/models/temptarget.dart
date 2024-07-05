import 'package:carer/models/model.dart';
import 'package:carer/sql/statements/carer_db_tables.dart';
import 'package:clock/clock.dart';
import 'package:signals/signals_flutter.dart';

class TempTargetRepository extends ModelRepository<TempTarget> {
  TempTargetRepository() : super(temptargetsTableName, timestampField: "start");

  @override
  TempTarget fromMap(Map<String, Object?> map) {
    var requiredKeys = ["start", "duration", "highTarget", "lowTarget", "nsid"];
    if (!(validateNotNull(map, requiredKeys) && validateType(map, requiredKeys, [int, int, int, int, String]))) {
      throw ArgumentError("Invalid SVG Map: $map");
    }

    return TempTarget(
      id: map["id"] as int?,
      nsid: map["nsid"] as String,
      startDate: DateTime.fromMillisecondsSinceEpoch(map["start"] as int),
      duration: map["duration"] as int,
      highTarget: map["highTarget"] as int,
      lowTarget: map["lowTarget"] as int,
    );
  }

  @override
  Map<String, Object> toSQLMap(TempTarget model) {
    return {
      "start": model.startDate.millisecondsSinceEpoch,
      "duration": model.duration,
      "highTarget": model.highTarget,
      "lowTarget": model.lowTarget,
      "nsid": model.nsid,
    };
  }
}

class TempTarget extends Model {
  static final TempTargetRepository _q = TempTargetRepository();

  @override
  ModelRepository get repository => _q;

  @override
  int? id;
  String nsid;
  @override
  get date => startDate;

  final DateTime startDate;
  final int duration;
  final int lowTarget;
  final int highTarget;

  TempTarget({
    this.id,
    required this.nsid,
    required this.startDate,
    required this.duration,
    required this.lowTarget,
    required this.highTarget,
  });

  @override
  List<String> uniqueValues() {
    return ["nsid"];
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

  static Future<List<TempTarget>> query({int? after, int? before, int? limit}) async {
    return _q.query(after: after, before: before, limit: limit);
  }

  static Future<TempTarget?> atTime(DateTime date) async {
    var ms = date.millisecondsSinceEpoch;
    return (await _q.query(conditions: {"start <= ?": ms, "end >= ?": ms}, limit: 1)).firstOrNull;
  }

  static Future<int> saveAll(List<TempTarget> models) => _q.saveAll(models);
  static Signal<int> get writeSignal => _q.writeSignal;
}
