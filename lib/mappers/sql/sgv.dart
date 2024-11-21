import 'package:carer/mappers/mapper.dart';
import 'package:carer/models/sql/sgv.dart';
import 'package:carer/sql/sqlmodel.dart';
import 'package:carer/sql/statements/carer_db_tables.dart';
import 'package:clock/clock.dart';

class SQLToSGV extends SQLMapper<SGV> {
  static final SQLToSGV _singleton = SQLToSGV._();
  factory SQLToSGV() => _singleton;
  SQLToSGV._();

  @override
  String get tableName => sgvsTableName; //TODO

  @override
  SGV aToB(SQLRow row) {
    List<String> errors = [];

    errors.addAll(row.validateRequiredAttributes(["value", "timestamp", "eid"]));
    errors.addAll(row.validateTypes([
      ("value", int),
      ("timestamp", int),
      ("eid", String),
    ]));

    if (errors.isNotEmpty) {
      throw ArgumentError("Invalid SVG Row: $row, Errors: $errors");
    }

    return SGV(
      id: row["id"] as int?,
      eid: row["eid"] as String,
      value: row["value"] as int,
      date: DateTime.fromMillisecondsSinceEpoch(row["timestamp"] as int),
    );
  }

  @override
  SQLRow bToA(SGV model) {
    return SQLRow({
      "value": model.value,
      "timestamp": model.date.millisecondsSinceEpoch,
      "eid": model.eid!,
    });
  }

  Future<List<SGV>> last2Days() {
    DateTime now = clock.now();
    DateTime startOfYesterday = DateTime(now.year, now.month, now.day - 1);
    int startOfYesterdayEpoch = startOfYesterday.millisecondsSinceEpoch;
    return SQLToSGV().query(after: startOfYesterdayEpoch);
  }
}
