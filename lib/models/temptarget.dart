import 'package:carer/mappers/sql_mappers.dart';
import 'package:carer/models/model.dart';

class TempTarget extends DateRangeModel {
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
    return SQLToTempTarget().query(after: after, before: before, limit: limit);
  }

  static Future<TempTarget?> atTime(DateTime date) async {
    var ms = date.millisecondsSinceEpoch;
    return (await SQLToTempTarget().query(conditions: {"start <= ?": ms, "end >= ?": ms}, limit: 1)).firstOrNull;
  }

  static Future<List<TempTarget>> after(DateTime date) async {
    return SQLToTempTarget().query(conditions: {
      "end >= ?": date.millisecondsSinceEpoch,
    });
  }

  @override
  String toString() {
    return "TempTarget($eid, $startDate, $duration, $lowTarget, $highTarget)";
  }
}
