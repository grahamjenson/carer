import 'package:carer/mappers/sql_mappers.dart';
import 'package:carer/models/model.dart';

class TempBasal extends DateRangeModel {
  final double value;

  TempBasal({
    super.id,
    required super.eid,
    required super.startDate,
    required super.duration,
    required this.value,
  });

  static Future<List<TempBasal>> query({int? after, int? before, int? limit}) async {
    return SQLToTempBasal().query(after: after, before: before, limit: limit);
  }

  static Future<TempBasal?> atTime(DateTime date) async {
    var ms = date.millisecondsSinceEpoch;
    return (await SQLToTempBasal().query(conditions: {"start <= ?": ms, "end >= ?": ms}, limit: 1)).firstOrNull;
  }

  static Future<List<TempBasal>> after(DateTime date) async {
    return SQLToTempBasal().query(conditions: {
      "end >= ?": date.millisecondsSinceEpoch,
    });
  }

  @override
  String toString() {
    return "TempBasal($eid, $startDate, $duration, $value)";
  }
}
