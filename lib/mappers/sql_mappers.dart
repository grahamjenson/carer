import 'package:carer/mappers/mapper.dart';
import 'package:carer/models/bolus.dart';
import 'package:carer/models/carbs.dart';
import 'package:carer/models/profile.dart';
import 'package:carer/models/sgv.dart';
import 'package:carer/models/tempbasal.dart';
import 'package:carer/models/temptarget.dart';
import 'package:carer/models/treatments.dart';
import 'package:carer/sql/sqlmodel.dart';
import 'package:carer/sql/statements/carer_db_tables.dart';

////
// Bolus
////
class SQLToBolus extends SQLMapper<Bolus> {
  static final SQLToBolus _singleton = SQLToBolus._();
  factory SQLToBolus() => _singleton;
  SQLToBolus._();

  @override
  String get tableName => bolusTableName;

  @override
  Bolus aToB(SQLRow row) {
    List<String> errors = [];

    errors.addAll(row.validateRequiredAttributes(["value", "timestamp", "eid"]));
    errors.addAll(row.validateTypes([
      ("value", double),
      ("timestamp", int),
      ("eid", String),
    ]));

    if (errors.isNotEmpty) {
      throw ArgumentError("Invalid Bolus Row: $row, Errors: $errors");
    }

    return Bolus(
      id: row["id"] as int?,
      eid: row["eid"] as String,
      value: row["value"] as double,
      date: DateTime.fromMillisecondsSinceEpoch(row["timestamp"] as int),
    );
  }

  @override
  SQLRow bToA(Bolus model) {
    return SQLRow({
      "value": model.value,
      "timestamp": model.date.millisecondsSinceEpoch,
      "eid": model.eid!,
    });
  }
}

////
// Carbs
////

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
}

////
// Profile
////

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

////
// SGV
////

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
}

class SQLToCleanSGV extends SQLReadMapper<CleanSGV> {
  static final SQLToCleanSGV _singleton = SQLToCleanSGV._();
  factory SQLToCleanSGV() => _singleton;
  SQLToCleanSGV._();

  @override
  String get tableName => sgvsCleanViewName;

  @override
  CleanSGV aToB(SQLRow row) {
    List<String> errors = [];

    errors.addAll(row.validateRequiredAttributes(["value", "timestamp", "eid"]));
    errors.addAll(row.validateTypes([
      ("value", int),
      ("timestamp", int),
      ("eid", String),
      ("rate5m", int),
      ("diff", int),
      ("id_before", int),
    ]));

    if (errors.isNotEmpty) {
      throw ArgumentError("Invalid SVG Row: $row, Errors: $errors");
    }

    return CleanSGV(
      id: row["id"] as int?,
      eid: row["eid"] as String,
      value: row["value"] as int,
      date: DateTime.fromMillisecondsSinceEpoch(row["timestamp"] as int),
      rate5m: row["rate5m"] as int?,
      diff: row["diff"] as int?,
      idBefore: row["id_before"] as int?,
    );
  }
}

////
// TempBasal
////

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
    );
  }

  @override
  SQLRow bToA(TempBasal model) {
    return SQLRow({
      "start": model.startDate.millisecondsSinceEpoch,
      "duration": model.duration,
      "value": model.value,
      "eid": model.eid!,
    });
  }
}

////
// TempTarget
////

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
}

////
// Treatments
////

class SQLToTreatment extends SQLReadMapper<Treatment> {
  static final SQLToTreatment _singleton = SQLToTreatment._();
  factory SQLToTreatment() => _singleton;
  SQLToTreatment._();

  @override
  String get tableName => concatTreatmentsViewName;

  @override
  Treatment aToB(SQLRow row) {
    List<String> errors = [];

    errors.addAll(row.validateRequiredAttributes(["count", "max_ts", "timestamp"]));
    errors.addAll(row.validateTypes([
      ("count", int),
      ("max_ts", int),
      ("timestamp", int),
      ("carbs", int),
      ("insulin", double),
    ]));

    if (errors.isNotEmpty) {
      throw ArgumentError("Invalid Treatment Row: $row, Errors: $errors");
    }

    return Treatment(
      count: row["count"] as int,
      date: DateTime.fromMillisecondsSinceEpoch(row["max_ts"] as int),
      carbs: row["carbs"] as int?,
      insulin: row["insulin"] as double?,
    );
  }
}
