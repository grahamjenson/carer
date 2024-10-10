import 'package:carer/mappers/mapper.dart';
import 'package:carer/models/sql/profile.dart';
import 'package:carer/sql/sqlmodel.dart';
import 'package:carer/sql/statements/carer_db_tables.dart';

class SQLToProfile extends SQLMapper<Profile> {
  static final SQLToProfile _singleton = SQLToProfile._();
  factory SQLToProfile() => _singleton;
  SQLToProfile._();

  @override
  String get tableName => profileTableName;

  @override
  Profile aToB(SQLRow row) {
    List<int> carbratio = crKeys.map((key) => row[key] as int).toList();
    List<int> sens = isfKeys.map((key) => row[key] as int).toList();
    List<double> basal = basalKeys.map((key) => row[key] as double).toList();
    List<int> lowTarget = lowTargetKeys.map((key) => row[key] as int).toList();
    List<int> highTarget = highTargetKeys.map((key) => row[key] as int).toList();

    return Profile(
      id: row["id"] as int?,
      name: row["name"] as String,
      eid: row["eid"] as String,
      startDate: DateTime.fromMillisecondsSinceEpoch(row["start"] as int),
      dia: row["dia"] as int,
      units: row["units"] as String,
      timezone: row["timezone"] as String,
      carbratio: carbratio,
      sens: sens,
      basal: basal,
      lowTarget: lowTarget,
      highTarget: highTarget,
      duration: row["duration"] as int,
      source: row["source"] as String,
      percent: row["percent"] as int,
    );
  }

  @override
  SQLRow bToA(Profile model) {
    Map<String, Object> map = {
      "name": model.name,
      "eid": model.eid!,
      "dia": model.dia,
      "units": model.units,
      "timezone": model.timezone,
      "start": model.startDate.millisecondsSinceEpoch,
      "duration": model.duration,
      "source": model.source,
      "percent": model.percent,
    };
    model.carbratio.asMap().forEach((index, value) {
      map[crKeys[index]] = value;
    });
    model.sens.asMap().forEach((index, value) {
      map[isfKeys[index]] = value;
    });
    model.basal.asMap().forEach((index, value) {
      map[basalKeys[index]] = value;
    });
    model.lowTarget.asMap().forEach((index, value) {
      map[lowTargetKeys[index]] = value;
    });
    model.highTarget.asMap().forEach((index, value) {
      map[highTargetKeys[index]] = value;
    });

    return SQLRow(map);
  }
}
