import 'package:carer/models/model.dart';
import 'package:carer/sql/statements/carer_db_tables.dart';
import 'package:carer/utils/math.dart';
import 'package:signals/signals_flutter.dart';

class BolusRepository extends ModelRepository<Bolus> {
  BolusRepository() : super(bolusTableName);

  @override
  Bolus fromMap(Map<String, Object?> map) {
    var requiredKeys = ["value", "timestamp", "eid"];
    if (!(validateNotNull(map, requiredKeys) &&
        validateType(map, [
          ("value", double),
          ("timestamp", int),
          ("eid", String),
        ]))) {
      throw ArgumentError("Invalid Bolus Map: $map");
    }

    return Bolus(
      id: map["id"] as int?,
      eid: map["eid"] as String,
      value: map["value"] as double,
      date: DateTime.fromMillisecondsSinceEpoch(map["timestamp"] as int),
    );
  }

  @override
  Map<String, Object> toSQLMap(Bolus model) {
    return {
      "value": model.value,
      "timestamp": model.date.millisecondsSinceEpoch,
      "eid": model.eid!,
    };
  }
}

class Bolus extends Model {
  static final BolusRepository _q = BolusRepository();

  @override
  ModelRepository get repository => _q;

  final double value;
  @override
  final DateTime date;

  Bolus({
    super.id,
    required super.eid,
    required this.value,
    required this.date,
  });

  factory Bolus.fromMap(Map<String, Object?> map) {
    return _q.fromMap(map);
  }

  String get str {
    if (value != 0) {
      return '${toMax2dp(value)}u';
    } else {
      return "";
    }
  }

  static Future<List<Bolus>> lastMins(int minsAgo) async {
    return _q.lastMins(minsAgo);
  }

  static Signal<int> get writeSignal => _q.writeSignal;
  static Future<int> saveAll(List<Bolus> models) => _q.saveAll(models);
}
