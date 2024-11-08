import 'dart:convert';

import 'package:carer/mappers/mapper.dart';
import 'package:carer/models/details/alarms/alarms.dart';
import 'package:carer/models/sql/logs/alarm_logs.dart';
import 'package:carer/sql/sqlmodel.dart';
import 'package:carer/sql/statements/carer_db_tables.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/utils/logs.dart';
import 'package:clock/clock.dart';

class SQLToAlarmLogs extends SQLMapper<AlarmLog> {
  static final SQLToAlarmLogs _singleton = SQLToAlarmLogs._();
  factory SQLToAlarmLogs() => _singleton;
  SQLToAlarmLogs._() {
    signalAssign(lastCoupleDays, () async => await last2Days(), debugLabel: "AlarmLogslastCoupleDays", dependencies: [writeSignal]);
  }

  final ASignal<List<AlarmLog>> lastCoupleDays = ASignal<List<AlarmLog>>([], debugLabel: "AlarmLogslastCoupleDays");

  @override
  String get tableName => alarmLogsTableName;

  @override
  AlarmLog aToB(SQLRow row) {
    List<String> errors = [];

    errors.addAll(row.validateRequiredAttributes([
      "type",
      "stage",
      "conditions",
      "start",
    ]));

    errors.addAll(row.validateTypes([
      ("type", String),
      ("stage", String),
      ("conditions", String),
      ("start", int),
      ("end", int),
    ]));

    if (errors.isNotEmpty) {
      throw ArgumentError("Invalid Alarms Row: $row, Errors: $errors");
    }

    AlarmType type = AlarmType.fromName(row["type"] as String);
    AlarmStage stage = AlarmStage.fromName(row["stage"] as String);
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

    return AlarmLog(
      id: row["id"] as int?,
      type: type,
      stage: stage,
      conditions: conditions,
      startDate: DateTime.fromMillisecondsSinceEpoch(row["start"] as int),
      endDate: endDate,
    );
  }

  @override
  SQLRow bToA(AlarmLog model) {
    var row = SQLRow({
      "type": model.type.name,
      "stage": model.stage.name,
      "conditions": jsonEncode(model.conditions),
      "start": model.date.millisecondsSinceEpoch,
    });

    if (model.endDate != null) {
      row["end"] = model.endDate!.millisecondsSinceEpoch;
    }
    return row;
  }

  Future<List<AlarmLog>> last2Days() {
    DateTime now = clock.now();
    DateTime startOfYesterday = DateTime(now.year, now.month, now.day - 1);
    int startOfYesterdayEpoch = startOfYesterday.millisecondsSinceEpoch;

    return query(after: startOfYesterdayEpoch);
  }

  Future<AlarmLog?> findUnfinishedAlarmOfTypeAndStage(AlarmType type, AlarmStage stage) async {
    var res = await query(conditions: {
      "type = ?": type.name,
      "stage = ?": stage.name,
      "end IS NULL": null,
    }, limit: 1);
    if (res.isEmpty) {
      return null;
    }
    return res.first;
  }
}
