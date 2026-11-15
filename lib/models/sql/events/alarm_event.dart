import 'package:carer/mappers/sql/events.dart';
import 'package:carer/models/details/alarms/alarms.dart';
import 'package:carer/models/sql/events/event.dart';
import 'package:clock/clock.dart';

enum AlarmStage {
  pending,
  alerting,
  unknown;

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
class AlarmEvent extends EventModel {
  AlarmEvent({
    super.id,
    super.type = EventType.alarm,
    required super.startDate,
    super.endDate,
    required super.details,
  });

  AlarmType get alarmType => AlarmType.fromName(detailStrOr("alarmType", "unknown"));
  AlarmStage get stage => AlarmStage.fromName(detailStrOr("stage", "unknown"));

  // static methods

  static Future<void> updateAlarmEvent(AlarmSet alarms, AlarmSet? previousAlarms, AlarmStage stage) async {
    var newAlarms = alarms;
    var removedAlarms = AlarmSet({});
    if (previousAlarms != null) {
      newAlarms = alarms.difference(previousAlarms);
      removedAlarms = previousAlarms.difference(alarms);
    }

    // Write the alarms

    // // if there is a new value then create a new alarm
    for (var newAlarm in newAlarms) {
      var details = newAlarm.details();
      details["stage"] = stage.name;
      details["alarmType"] = newAlarm.name;

      var log = AlarmEvent(
        details: details,
        startDate: clock.now(),
      );
      await SQLToEvents().save(log);
    }

    // If there is a removed Value then remove the alarm
    for (var removedAlarm in removedAlarms) {
      var event = await findUnfinishedAlarmOfTypeAndStage(removedAlarm, stage);
      if (event == null) {
        continue;
      }
      event.endDate = clock.now();
      await SQLToEvents().save(event);
    }
  }

  static Future<AlarmEvent?> findUnfinishedAlarmOfTypeAndStage(AlarmType alarmType, AlarmStage stage) async {
    var unfinishedAlarms = await SQLToEvents().unfinishedEventsOfType(EventType.alarm);
    for (var event in unfinishedAlarms) {
      AlarmEvent alarm = event as AlarmEvent;
      if (alarm.alarmType == alarmType && alarm.stage == stage) {
        return alarm;
      }
    }

    return null;
  }
}
