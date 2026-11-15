import 'package:carer/mappers/sql/events.dart';
import 'package:carer/models/sql/events/event.dart';
import 'package:clock/clock.dart';

enum AppStateEventType {
  detached,
  resumed,
  inactive,
  hidden,
  paused,
  unknown;

  static AppStateEventType fromName(String stage) {
    for (var t in AppStateEventType.values) {
      if (t.name == stage) {
        return t;
      }
    }
    throw ArgumentError("Invalid AppStateEventType: $stage");
  }
}

// This is a record of all triggered alarms.
class AppStateEvent extends EventModel {
  AppStateEvent({
    super.id,
    required super.startDate,
    super.type = EventType.appState,
    super.endDate,
    required super.details,
  });

  AppStateEventType get stage => AppStateEventType.fromName(detailStrOr("state", "unknown"));

  // Static methods
  static Future<void> appStateChange(AppStateEventType state) async {
    // This might extend a previous snooze, which we can find

    var map = {
      "state": state.name,
    };

    SQLToEvents().save(AppStateEvent(startDate: clock.now(), details: map));
  }
}
