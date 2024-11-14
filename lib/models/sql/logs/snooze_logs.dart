import 'package:carer/models/sql/logs/log.dart';

// This is a record of all triggered alarms.
class SnoozeLog extends LogDBModel {
  SnoozeLog({
    super.id,
    required super.startDate,
    super.endDate,
    required super.conditions,
  });
}
