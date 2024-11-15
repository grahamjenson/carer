import 'package:carer/models/sql/db_model.dart';
import 'package:clock/clock.dart';

enum EventType {
  alarm,
  snooze,
  appState;

  static EventType fromName(String name) {
    for (var alarm in EventType.values) {
      if (alarm.name == name) {
        return alarm;
      }
    }
    throw ArgumentError("Invalid Alarm Name: $name");
  }
}

class EventModel extends DBModel {
  @override
  get date => startDate;

  final DateTime startDate;
  DateTime? endDate;
  final Map<String, dynamic> details;
  final EventType type;
  Duration get duration => endDate != null ? endDate!.difference(startDate) : clock.now().difference(startDate);

  EventModel({
    super.id,
    super.eid,
    required this.startDate,
    required this.type,
    this.endDate,
    required this.details,
  });

  String detailStrOr(String key, String or) {
    if (!details.containsKey(key)) {
      return or;
    }
    return details[key] as String;
  }
}
