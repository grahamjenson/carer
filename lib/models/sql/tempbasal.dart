import 'package:carer/mappers/sql/tempbasal.dart';
import 'package:carer/models/sql/db_model.dart';

class TempBasal extends DateRangeDBModel {
  final double value;
  // percent is the change from the profile's basal of a percent temp basal (40 is 140 %), whose rate is then the
  // profile's at each minute; null for an absolute rate, value
  final int? percent;

  TempBasal({
    super.id,
    required super.eid,
    required super.startDate,
    required super.duration,
    required this.value,
    this.percent,
  });

  // rateWith is the temp basal's rate when the profile's basal is profileBasal
  double rateWith(double? profileBasal) {
    if (percent == null || profileBasal == null) {
      return value;
    }
    return profileBasal * (100 + percent!) / 100;
  }

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
    return "TempBasal($eid, $startDate, $duration, $value, $percent)";
  }
}
