import 'package:carer/mappers/mapper.dart';
import 'package:carer/models/sql/temptarget.dart';
import 'package:carer/sql/sqlmodel.dart';
import 'package:carer/sql/statements/carer_db_tables.dart';

class SQLToTempTarget extends SQLMapper<TempTarget> {
  static final SQLToTempTarget _singleton = SQLToTempTarget._();
  factory SQLToTempTarget() => _singleton;
  SQLToTempTarget._();

  @override
  String get tableName => temptargetsTableName;

  @override
  TempTarget aToB(SQLRow row) {
    List<String> errors = [];

    errors.addAll(row.validateRequiredAttributes(["start", "duration", "highTarget", "lowTarget", "eid"]));
    errors.addAll(row.validateTypes([
      ("start", int),
      ("duration", int),
      ("highTarget", int),
      ("lowTarget", int),
      ("eid", String),
    ]));

    if (errors.isNotEmpty) {
      throw ArgumentError("Invalid TempBasal Row: $row, Errors: $errors");
    }

    return TempTarget(
      id: row["id"] as int?,
      eid: row["eid"] as String,
      startDate: DateTime.fromMillisecondsSinceEpoch(row["start"] as int),
      duration: row["duration"] as int,
      highTarget: row["highTarget"] as int,
      lowTarget: row["lowTarget"] as int,
    );
  }

  @override
  SQLRow bToA(TempTarget model) {
    return SQLRow({
      "start": model.startDate.millisecondsSinceEpoch,
      "duration": model.duration,
      "highTarget": model.highTarget,
      "lowTarget": model.lowTarget,
      "eid": model.eid!,
    });
  }

  @override
  bool equals(SQLRow row, TempTarget model) {
    var modelRow = bToA(model);
    return modelRow["start"] == row["start"] &&
        modelRow["duration"] == row["duration"] &&
        modelRow["highTarget"] == row["highTarget"] &&
        modelRow["lowTarget"] == row["lowTarget"] &&
        modelRow["eid"] == row["eid"];
  }
}
