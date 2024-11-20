import 'dart:convert';

import 'package:carer/mappers/mapper.dart';
import 'package:carer/models/sql/events/alarm_event.dart';
import 'package:carer/models/sql/events/app_state_change_event.dart';
import 'package:carer/models/sql/events/event.dart';
import 'package:carer/models/sql/events/snooze_events.dart';
import 'package:carer/sql/sqlmodel.dart';
import 'package:carer/sql/statements/carer_db_tables.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/utils/logs.dart';
import 'package:clock/clock.dart';

class SQLToEvents extends SQLMapper<EventModel> {
  static final SQLToEvents _singleton = SQLToEvents._();
  factory SQLToEvents() => _singleton;
  SQLToEvents._() {
    signalAssign(lastCoupleDays, () async => await last2Days(), debugLabel: "fetchAlarmLogslastCoupleDays", dependencies: [writeSignal]);
  }

  final ASignal<List<EventModel>> lastCoupleDays = ASignal<List<EventModel>>([], debugLabel: "AlarmLogslastCoupleDays");

  @override
  String get tableName => eventsTableName;

  @override
  EventModel aToB(SQLRow row) {
    List<String> errors = [];

    errors.addAll(row.validateRequiredAttributes([
      "type",
      "details",
      "start",
    ]));

    errors.addAll(row.validateTypes([
      ("type", String),
      ("details", String),
      ("start", int),
      ("end", int),
    ]));

    if (errors.isNotEmpty) {
      throw ArgumentError("Invalid Events Row: $row, Errors: $errors");
    }

    EventType type = EventType.fromName(row["type"] as String);

    // decode the details from json
    Map<String, dynamic> details = {};
    try {
      details = jsonDecode(row["details"] as String);
    } catch (e) {
      alog("SQLToEvents SQL MApper: Bad details json: ${row["details"]}", error: e);
    }

    DateTime? endDate;
    if (row["end"] != null) {
      endDate = DateTime.fromMillisecondsSinceEpoch(row["end"] as int);
    }

    switch (type) {
      case EventType.alarm:
        return AlarmEvent(
          id: row["id"] as int?,
          details: details,
          startDate: DateTime.fromMillisecondsSinceEpoch(row["start"] as int),
          endDate: endDate,
        );
      case EventType.snooze:
        return SnoozeEvent(
          id: row["id"] as int?,
          details: details,
          startDate: DateTime.fromMillisecondsSinceEpoch(row["start"] as int),
          endDate: endDate,
        );
      case EventType.appState:
        return AppStateEvent(
          id: row["id"] as int?,
          details: details,
          startDate: DateTime.fromMillisecondsSinceEpoch(row["start"] as int),
          endDate: endDate,
        );
    }
  }

  @override
  SQLRow bToA(EventModel model) {
    var row = SQLRow({
      "type": model.type.name,
      "details": jsonEncode(model.details),
      "start": model.date.millisecondsSinceEpoch,
    });

    if (model.endDate != null) {
      row["end"] = model.endDate!.millisecondsSinceEpoch;
    }
    return row;
  }

  Future<List<EventModel>> last2Days() {
    DateTime now = clock.now();
    DateTime startOfYesterday = DateTime(now.year, now.month, now.day - 1);
    int startOfYesterdayEpoch = startOfYesterday.millisecondsSinceEpoch;

    return query(after: startOfYesterdayEpoch);
  }

  Future<List<EventModel>> unfinishedEventsOfType(EventType type) async {
    List<EventModel> ll = await last2Days();
    return ll.where((e) => e.type == type && e.endDate == null).toList();
  }
}
