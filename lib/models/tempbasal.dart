import 'package:carer/mappers/sql_mappers.dart';
import 'package:carer/models/model.dart';
import 'package:carer/sql/sqlmodel.dart';
import 'package:carer/sql/statements/carer_db_tables.dart';
import 'package:signals/signals_flutter.dart';

class TempBasalRepository extends ModelRepository<TempBasal> {
  TempBasalRepository() : super(tempbasalTableName, timestampField: "start");

  @override
  TempBasal fromMap(Map<String, Object?> map) {
    return SQLToTempBasal().aToB(SQLRow(map));
  }

  @override
  Map<String, Object> toSQLMap(TempBasal model) {
    return SQLToTempBasal().bToA(model).toCleanMap();
  }
}

class TempBasal extends DateRangeModel {
  static final TempBasalRepository _q = TempBasalRepository();

  @override
  ModelRepository get repository => _q;

  final double value;

  TempBasal({
    super.id,
    required super.eid,
    required super.startDate,
    required super.duration,
    required this.value,
  });

  static Future<List<TempBasal>> query({int? after, int? before, int? limit}) async {
    return _q.query(after: after, before: before, limit: limit);
  }

  static Future<TempBasal?> atTime(DateTime date) async {
    var ms = date.millisecondsSinceEpoch;
    return (await _q.query(conditions: {"start <= ?": ms, "end >= ?": ms}, limit: 1)).firstOrNull;
  }

  static Future<List<TempBasal>> after(DateTime date) async {
    return _q.query(conditions: {
      "end >= ?": date.millisecondsSinceEpoch,
    });
  }

  static Future<int> saveAll(List<TempBasal> models) => _q.saveAll(models);
  static Future<int> upsertAll(List<TempBasal> models) => _q.upsertAll(models);

  static Signal<int> get writeSignal => _q.writeSignal;
}
