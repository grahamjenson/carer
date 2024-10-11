import 'package:carer/models/sql/db_model.dart';
import 'package:carer/services/alarms/alarms.dart';

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
class AlarmLog extends DBModel {
  @override
  get date => startDate;
  final DateTime startDate;

  DateTime? endDate;

  final AlarmType type;
  final AlarmStage stage;
  final Map<String, dynamic> conditions;

  AlarmLog({
    super.id,
    required this.startDate,
    this.endDate,
    required this.type,
    required this.stage,
    required this.conditions,
  });
}
