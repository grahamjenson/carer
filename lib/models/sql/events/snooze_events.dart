import 'package:carer/mappers/sql/events.dart';
import 'package:carer/models/sql/events/event.dart';
import 'package:carer/services/app_details_service.dart';
import 'package:carer/services/settings/alarm_alert_settings.dart';
import 'package:clock/clock.dart';

// This is a record of all triggered alarms.
class SnoozeEvent extends EventModel {
  SnoozeEvent({
    super.id,
    super.type = EventType.snooze,
    required super.startDate,
    super.endDate,
    required super.details,
  });

  // Static methods
  static Future<void> startSnooze(Duration duration, SnoozeReason reason) async {
    // This might extend a previous snooze, which we can find
    SnoozeEvent? unfinished = await findUnfinishedSnoozeLog();
    if (unfinished != null) {
      // Extend the previous snooze
      unfinished.endDate = clock.now();
      SQLToEvents().save(unfinished);
    }
    var time = clock.now().add(duration);
    var map = AppDetailsService().appDetails();
    map.addAll({
      "until": time.toIso8601String(),
      "duration": duration.inSeconds,
      "startReason": reason.name,
    });
    SQLToEvents().save(SnoozeEvent(startDate: clock.now(), details: map));
  }

  static Future<void> endSnooze(SnoozeReason reason) async {
    // Find a previous snooze
    SnoozeEvent? unfinished = await findUnfinishedSnoozeLog();
    if (unfinished != null) {
      // Extend the previous snooze
      unfinished.endDate = clock.now();
      unfinished.details["endReason"] = reason.name;
      SQLToEvents().save(unfinished);
    }
  }

  static Future<SnoozeEvent?> findUnfinishedSnoozeLog() async {
    var unfinishedSnoozes = await SQLToEvents().unfinishedEventsOfType(EventType.snooze);
    for (var event in unfinishedSnoozes) {
      SnoozeEvent snooze = event as SnoozeEvent;
      return snooze;
    }

    return null;
  }
}
