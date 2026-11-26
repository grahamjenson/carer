import 'package:carer/mappers/mapper.dart';
import 'package:carer/models/sql/tempbasal.dart';
import 'package:carer/sql/sqlmodel.dart';
import 'package:carer/sql/statements/carer_db_tables.dart';

class SQLToTempBasal extends SQLMapper<TempBasal> {
  static final SQLToTempBasal _singleton = SQLToTempBasal._();
  factory SQLToTempBasal() => _singleton;
  SQLToTempBasal._();

  @override
  String get tableName => tempbasalTableName;

  @override
  TempBasal aToB(SQLRow row) {
    List<String> errors = [];

    errors.addAll(row.validateRequiredAttributes(["value", "start", "duration", "eid"]));
    errors.addAll(row.validateTypes([
      ("value", double),
      ("start", int),
      ("duration", int),
      ("eid", String),
    ]));

    if (errors.isNotEmpty) {
      throw ArgumentError("Invalid TempBasal Row: $row, Errors: $errors");
    }

    return TempBasal(
      id: row["id"] as int?,
      eid: row["eid"] as String,
      startDate: DateTime.fromMillisecondsSinceEpoch(row["start"] as int),
      duration: row["duration"] as int,
      value: row["value"] as double,
      percent: row["percent"] as int?,
    );
  }

  @override
  SQLRow bToA(TempBasal model) {
    return SQLRow({
      "start": model.startDate.millisecondsSinceEpoch,
      "duration": model.duration,
      "value": model.value,
      "percent": model.percent,
      "eid": model.eid!,
    });
  }

  @override
  bool equals(SQLRow row, TempBasal model) {
    var modelRow = bToA(model);
    return modelRow["start"] == row["start"] &&
        modelRow["duration"] == row["duration"] &&
        modelRow["value"] == row["value"] &&
        modelRow["percent"] == row["percent"] &&
        modelRow["eid"] == row["eid"];
  }
}
