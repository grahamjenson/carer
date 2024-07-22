import 'package:carer/mappers/sql_mappers.dart';
import 'package:carer/models/model.dart';
import 'package:carer/sql/sqlmodel.dart';
import 'package:carer/sql/statements/carer_db_tables.dart';
import 'package:carer/utils/math.dart';
import 'package:signals/signals_flutter.dart';

class CarbsRepository extends ModelRepository<Carbs> {
  CarbsRepository() : super(carbsTableName);

  @override
  Carbs fromMap(Map<String, Object?> map) {
    return SQLToCarbs().aToB(SQLRow(map));
  }

  @override
  Map<String, Object> toSQLMap(Carbs model) {
    return SQLToCarbs().bToA(model).toCleanMap();
  }
}

class Carbs extends Model {
  static final CarbsRepository _q = CarbsRepository();

  @override
  ModelRepository get repository => _q;

  final int value;
  @override
  final DateTime date;

  Carbs({
    super.id,
    required super.eid,
    required this.value,
    required this.date,
  });

  String get str {
    if (value != 0) {
      return '${toMax2dp(value)}g';
    } else {
      return "";
    }
  }

  // return the last sgvs for minutes
  static Future<List<Carbs>> lastMins(int minsAgo) {
    return _q.lastMins(minsAgo);
  }

  static Signal<int> get writeSignal => _q.writeSignal;
  static Future<int> saveAll(List<Carbs> models) => _q.saveAll(models);
}
