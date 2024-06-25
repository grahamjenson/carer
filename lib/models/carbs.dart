import 'package:carer/models/model.dart';
import 'package:carer/sql/statements/carer_db_tables.dart';
import 'package:carer/utils/math.dart';
import 'package:signals/signals_flutter.dart';

class CarbsRepository extends ModelRepository<Carbs> {
  CarbsRepository() : super(carbsTableName);

  @override
  Carbs fromMap(Map<String, Object?> map) {
    var requiredKeys = ["value", "timestamp"];
    if (!(validateNotNull(map, requiredKeys) && validateType(map, requiredKeys, [int, int]))) {
      throw ArgumentError("Invalid Carbs Map: $map");
    }

    {
      return Carbs(
        id: map["id"] as int?,
        value: map["value"] as int,
        date: DateTime.fromMillisecondsSinceEpoch(map["timestamp"] as int),
      );
    }
  }

  @override
  Map<String, Object> toSQLMap(Carbs model) {
    return {
      "value": model.value,
      "timestamp": model.date.millisecondsSinceEpoch,
    };
  }
}

class Carbs extends Model {
  static final CarbsRepository _q = CarbsRepository();

  @override
  ModelRepository get repository => _q;

  @override
  int? id;

  final int value;
  @override
  final DateTime date;

  Carbs({
    this.id,
    required this.value,
    required this.date,
  });

  factory Carbs.fromMap(Map<String, Object?> map) {
    return _q.fromMap(map);
  }

  String get str {
    if (value != 0) {
      return '${toMax2dp(value)}g';
    } else {
      return "";
    }
  }

  // return the last sgvs for minutes
  static Future<List<Carbs>> lastMins(int minsAgo) async {
    return (await _q.lastMins(minsAgo));
  }

  static Signal<int> get writeSignal => _q.writeSignal;
  static Future<int> saveAll(List<Carbs> models) => _q.saveAll(models);
}
