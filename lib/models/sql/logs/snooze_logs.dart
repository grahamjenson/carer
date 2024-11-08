import 'package:carer/models/sql/db_model.dart';

// This is a record of all triggered alarms.
class SnoozeLog extends DBModel {
  @override
  get date => startDate;
  final DateTime startDate;

  // If no end Date then it has been stopped
  DateTime? endDate;

  final String reason;
  final Map<String, dynamic> conditions;

  SnoozeLog({
    super.id,
    required this.startDate,
    this.endDate,
    required this.reason,
    required this.conditions,
  });
}
