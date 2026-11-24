import 'package:carer/mappers/mapper.dart';
import 'package:carer/models/sql/carbs.dart';
import 'package:carer/sql/sqlmodel.dart';
import 'package:carer/sql/statements/carer_db_tables.dart';

class SQLToCarbs extends SQLMapper<Carbs> {
  static final SQLToCarbs _singleton = SQLToCarbs._();
  factory SQLToCarbs() => _singleton;
  SQLToCarbs._();

  @override
  String get tableName => carbsTableName;

  @override
  Carbs aToB(SQLRow row) {
    List<String> errors = [];

    errors.addAll(row.validateRequiredAttributes(["value", "timestamp", "eid"]));
    errors.addAll(row.validateTypes([
      ("value", int),
      ("timestamp", int),
      ("eid", String),
    ]));

    if (errors.isNotEmpty) {
      throw ArgumentError("Invalid Carbs Row: $row, Errors: $errors");
    }

    return Carbs(
      id: row["id"] as int?,
      eid: row["eid"] as String,
      value: row["value"] as int,
      date: DateTime.fromMillisecondsSinceEpoch(row["timestamp"] as int),
    );
  }

  @override
  SQLRow bToA(Carbs model) {
    return SQLRow({
      "value": model.value,
      "timestamp": model.date.millisecondsSinceEpoch,
      "eid": model.eid!,
    });
  }

  // A row is the model when every column it is written to is the same, so upsertAll updates carbs that changed
  @override
  bool equals(SQLRow row, Carbs model) {
    var modelRow = bToA(model);
    return modelRow["value"] == row["value"] && modelRow["timestamp"] == row["timestamp"] && modelRow["eid"] == row["eid"];
  }
}
