import 'package:carer/mappers/sql_mappers.dart';
import 'package:carer/models/model.dart';
import 'package:carer/sql/sqlmodel.dart';
import 'package:carer/sql/statements/carer_db_tables.dart';
import 'package:signals/signals_flutter.dart';

class TempTargetRepository extends ModelRepository<TempTarget> {
  TempTargetRepository() : super(temptargetsTableName, timestampField: "start");

  @override
  TempTarget fromMap(Map<String, Object?> map) {
    return SQLToTempTarget().aToB(SQLRow(map));
  }

  @override
  Map<String, Object> toSQLMap(TempTarget model) {
    return SQLToTempTarget().bToA(model).toCleanMap();
  }
}

class TempTarget extends DateRangeModel {
  static final TempTargetRepository _q = TempTargetRepository();

  @override
  ModelRepository get repository => _q;

  final int lowTarget;
  final int highTarget;

  TempTarget({
    super.id,
    required super.eid,
    required super.startDate,
    required super.duration,
    required this.lowTarget,
    required this.highTarget,
  });

  static Future<List<TempTarget>> query({int? after, int? before, int? limit}) async {
    return _q.query(after: after, before: before, limit: limit);
  }

  static Future<TempTarget?> atTime(DateTime date) async {
    var ms = date.millisecondsSinceEpoch;
    return (await _q.query(conditions: {"start <= ?": ms, "end >= ?": ms}, limit: 1)).firstOrNull;
  }

  static Future<List<TempTarget>> after(DateTime date) async {
    return _q.query(conditions: {
      "end >= ?": date.millisecondsSinceEpoch,
    });
  }

  static Future<int> saveAll(List<TempTarget> models) => _q.saveAll(models);
  static Future<int> upsertAll(List<TempTarget> models) => _q.upsertAll(models);

  static Signal<int> get writeSignal => _q.writeSignal;
}
