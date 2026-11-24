import 'package:carer/mappers/mapper.dart';
import 'package:carer/models/sql/bolus.dart';
import 'package:carer/sql/sqlmodel.dart';
import 'package:carer/sql/statements/carer_db_tables.dart';

class SQLToBolus extends SQLMapper<Bolus> {
  static final SQLToBolus _singleton = SQLToBolus._();
  factory SQLToBolus() => _singleton;
  SQLToBolus._();

  @override
  String get tableName => bolusTableName;

  @override
  Bolus aToB(SQLRow row) {
    List<String> errors = [];

    errors.addAll(row.validateRequiredAttributes(["value", "timestamp", "eid", "type"]));
    errors.addAll(row.validateTypes([
      ("value", double),
      ("timestamp", int),
      ("eid", String),
      ("type", String),
    ]));

    if (errors.isNotEmpty) {
      throw ArgumentError("Invalid Bolus Row: $row, Errors: $errors");
    }
    var type = BolusType.fromName(row["type"] as String);
    return Bolus(
      id: row["id"] as int?,
      eid: row["eid"] as String,
      value: row["value"] as double,
      type: type,
      date: DateTime.fromMillisecondsSinceEpoch(row["timestamp"] as int),
    );
  }

  @override
  SQLRow bToA(Bolus model) {
    return SQLRow({
      "value": model.value,
      "timestamp": model.date.millisecondsSinceEpoch,
      "eid": model.eid!,
      "type": model.type.name.toString(),
    });
  }

  // A row is the model when every column it is written to is the same, so upsertAll updates a bolus that changed
  @override
  bool equals(SQLRow row, Bolus model) {
    var modelRow = bToA(model);
    return modelRow["value"] == row["value"] &&
        modelRow["timestamp"] == row["timestamp"] &&
        modelRow["eid"] == row["eid"] &&
        modelRow["type"] == row["type"];
  }
}
