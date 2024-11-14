import 'package:carer/models/details/alarms/alarms.dart';
import 'package:carer/models/sql/logs/log.dart';

enum AlarmStage {
  pending,
  alerting;

  static AlarmStage fromName(String stage) {
    for (var t in AlarmStage.values) {
      if (t.name == stage) {
        return t;
      }
    }
    throw ArgumentError("Invalid Alarm Stage: $stage");
  }
}

// This is a record of all triggered alarms.
class AlarmLog extends LogDBModel {
  final AlarmType type;
  final AlarmStage stage;

  AlarmLog({
    super.id,
    required super.startDate,
    super.endDate,
    required this.type,
    required this.stage,
    required super.details,
  });
}
