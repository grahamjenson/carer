import 'dart:convert';

import 'package:carer/mappers/mapper.dart';
import 'package:carer/models/sql/logs/snooze_logs.dart';
import 'package:carer/services/app_state_service.dart';
import 'package:carer/services/settings/alarm_alert_settings.dart';
import 'package:carer/sql/sqlmodel.dart';
import 'package:carer/sql/statements/carer_db_tables.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/utils/logs.dart';
import 'package:clock/clock.dart';

class SQLToSnoozeLogs extends SQLMapper<SnoozeLog> {
  static final SQLToSnoozeLogs _singleton = SQLToSnoozeLogs._();
  factory SQLToSnoozeLogs() => _singleton;
  SQLToSnoozeLogs._() {
    signalAssign(lastCoupleDays, () async => await last2Days(), debugLabel: "SnoozeLogslastCoupleDays", dependencies: [writeSignal]);
  }

  final ASignal<List<SnoozeLog>> lastCoupleDays = ASignal<List<SnoozeLog>>([], debugLabel: "SnoozeLogslastCoupleDays");

  @override
  String get tableName => snoozeLogsTableName;

  @override
  SnoozeLog aToB(SQLRow row) {
    List<String> errors = [];

    errors.addAll(row.validateRequiredAttributes([
      "conditions",
      "start",
    ]));

    errors.addAll(row.validateTypes([
      ("conditions", String),
      ("start", int),
      ("end", int),
    ]));

    if (errors.isNotEmpty) {
      throw ArgumentError("Invalid Alarms Row: $row, Errors: $errors");
    }

    // decode the conditions from json
    Map<String, dynamic> conditions = {};
    try {
      conditions = jsonDecode(row["conditions"] as String);
    } catch (e) {
      alog("TriggeredAlarm SQL MApper: Bad conditions json: ${row["conditions"]}", error: e);
    }

    DateTime? endDate;
    if (row["end"] != null) {
      endDate = DateTime.fromMillisecondsSinceEpoch(row["end"] as int);
    }

    return SnoozeLog(
      id: row["id"] as int?,
      conditions: conditions,
      startDate: DateTime.fromMillisecondsSinceEpoch(row["start"] as int),
      endDate: endDate,
    );
  }

  @override
  SQLRow bToA(SnoozeLog model) {
    var row = SQLRow({
      "conditions": jsonEncode(model.conditions),
      "start": model.date.millisecondsSinceEpoch,
    });

    if (model.endDate != null) {
      row["end"] = model.endDate!.millisecondsSinceEpoch;
    }
    return row;
  }

  Future<List<SnoozeLog>> last2Days() {
    DateTime now = clock.now();
    DateTime startOfYesterday = DateTime(now.year, now.month, now.day - 1);
    int startOfYesterdayEpoch = startOfYesterday.millisecondsSinceEpoch;

    return query(after: startOfYesterdayEpoch);
  }

  Future<void> startSnooze(Duration duration, SnoozeReason reason) async {
    // This might extend a previous snooze, which we can find
    SnoozeLog? unfinished = await findUnfinishedSnoozeLog();
    if (unfinished != null) {
      // Extend the previous snooze
      unfinished.endDate = clock.now();
      save(unfinished);
    }
    var time = clock.now().add(duration);
    var map = AppStateService().appState();
    map.addAll({
      "until": time.toIso8601String(),
      "duration": duration.inSeconds,
      "startReason": reason.name,
    });
    save(SnoozeLog(startDate: clock.now(), conditions: map));
  }

  Future<void> endSnooze(SnoozeReason reason) async {
    // Find a previous snooze
    SnoozeLog? unfinished = await findUnfinishedSnoozeLog();
    if (unfinished != null) {
      // Extend the previous snooze
      unfinished.endDate = clock.now();
      unfinished.conditions["endReason"] = reason.name;
      save(unfinished);
    }
  }

  Future<SnoozeLog?> findUnfinishedSnoozeLog() async {
    var res = await query(conditions: {
      "end IS NULL": null,
    }, limit: 1);
    if (res.isEmpty) {
      return null;
    }
    return res.first;
  }
}
