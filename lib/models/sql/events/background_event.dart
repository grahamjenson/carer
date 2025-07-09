import 'package:carer/mappers/sql/events.dart';
import 'package:carer/models/clean_sgv.dart';
import 'package:carer/models/sql/events/event.dart';
import 'package:carer/services/app_details_service.dart';

// This is a record of all triggered alarms.
class BackgroundEvent extends EventModel {
  BackgroundEvent({
    super.id,
    super.type = EventType.background,
    required super.startDate,
    required super.endDate,
    required super.details,
  });

  Future<void> save() async {
    await SQLToEvents().save(this);
  }

  // Static methods
  static Future<void> saveBackgroundEvent(DateTime start, DateTime end, CleanSGV? startSGV, CleanSGV? endSGV, String alarms) async {
    var map = AppDetailsService().appDetails();
    map.addAll({
      "startSGV": "$startSGV",
      "endSGV": "$endSGV",
      "alarms": alarms,
      "duration": "${end.difference(start).inSeconds}s",
    });
    SQLToEvents().save(BackgroundEvent(startDate: start, endDate: end, details: map));
  }
}
