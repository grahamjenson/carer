import 'package:carer/mappers/sql_mappers.dart';
import 'package:carer/models/model.dart';
import 'package:carer/sql/sqlmodel.dart';
import 'package:carer/sql/statements/carer_db_tables.dart';
import 'package:carer/utils/math.dart';
import 'package:signals/signals_flutter.dart';

class BolusRepository extends ModelRepository<Bolus> {
  BolusRepository() : super(bolusTableName);

  @override
  Bolus fromMap(Map<String, Object?> map) {
    return BolusToSQLRow().from(SQLRow(bolusTableName, map));
  }

  @override
  Map<String, Object> toSQLMap(Bolus model) {
    return SQLRowToBolus().from(model).toCleanMap();
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

  String get str {
    if (value != 0) {
      return '${toMax2dp(value)}u';
    } else {
      return "";
    }
  }

  static Signal<int> get writeSignal => _q.writeSignal;
  static Future<int> saveAll(List<Bolus> models) => _q.saveAll(models);
}
