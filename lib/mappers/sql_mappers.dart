import 'package:carer/mappers/mapper.dart';
import 'package:carer/models/bolus.dart';
import 'package:carer/models/carbs.dart';
import 'package:carer/models/profile.dart';
import 'package:carer/models/sgv.dart';
import 'package:carer/models/tempbasal.dart';
import 'package:carer/models/temptarget.dart';
import 'package:carer/models/treatments.dart';
import 'package:carer/models/valueAtTime.dart';
import 'package:carer/sql/sqlmodel.dart';
import 'package:carer/sql/statements/carer_db_tables.dart';

////
// Bolus
////
class BolusToSQLRow extends DataMapper<SQLRow, Bolus> {
  @override
  Bolus from(SQLRow row) {
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
}

class SQLRowToBolus extends DataMapper<Bolus, SQLRow> {
  @override
  SQLRow from(Bolus model) {
    return SQLRow(bolusTableName, {
      "value": model.value,
      "timestamp": model.date.millisecondsSinceEpoch,
      "eid": model.eid!,
    });
  }
}

////
// Carbs
////

class CarbsToSQLRow extends DataMapper<SQLRow, Carbs> {
  @override
  Carbs from(SQLRow row) {
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
}

class SQLRowToCarbs extends DataMapper<Carbs, SQLRow> {
  @override
  SQLRow from(Carbs model) {
    return SQLRow(carbsTableName, {
      "value": model.value,
      "timestamp": model.date.millisecondsSinceEpoch,
      "eid": model.eid!,
    });
  }
}

////
// Profile
////

class ProfileToSQLRow extends DataMapper<SQLRow, Profile> {
  @override
  Profile from(SQLRow row) {
    List<int> carbratio = crKeys.map((key) => row[key] as int).toList();
    List<int> sens = isfKeys.map((key) => row[key] as int).toList();
    List<double> basal = basalKeys.map((key) => row[key] as double).toList();
    List<int> lowTarget = lowTargetKeys.map((key) => row[key] as int).toList();
    List<int> highTarget = highTargetKeys.map((key) => row[key] as int).toList();

    {
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
  }
}

class SQLRowToProfile extends DataMapper<Profile, SQLRow> {
  @override
  SQLRow from(Profile model) {
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

    return SQLRow(profileTableName, map);
  }
}

////
// SGV
////

class CleanSGVToSQLRow extends DataMapper<SQLRow, SGV> {
  @override
  SGV from(SQLRow row) {
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
      rate5m: row["rate5m"] as int?,
      diff: row["diff"] as int?,
      idBefore: row["id_before"] as int?,
    );
  }
}

class SQLRowToSGV extends DataMapper<SGV, SQLRow> {
  @override
  SQLRow from(SGV model) {
    return SQLRow(sgvsTableName, {
      "value": model.value,
      "timestamp": model.date.millisecondsSinceEpoch,
      "eid": model.eid!,
    });
  }
}

////
// TempBasal
////

class TempBasalToSQLRow extends DataMapper<SQLRow, TempBasal> {
  @override
  TempBasal from(SQLRow row) {
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
}

class SQLRowToTempBasal extends DataMapper<TempBasal, SQLRow> {
  @override
  SQLRow from(TempBasal model) {
    return SQLRow(tempbasalTableName, {
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

class TempTargetToSQLRow extends DataMapper<SQLRow, TempTarget> {
  @override
  TempTarget from(SQLRow row) {
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
}

class SQLRowToTempTarget extends DataMapper<TempTarget, SQLRow> {
  @override
  SQLRow from(TempTarget model) {
    return SQLRow(temptargetsTableName, {
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

class TreatmentToSQLRow extends DataMapper<SQLRow, Treatment> {
  @override
  Treatment from(SQLRow row) {
    List<String> errors = [];

    errors.addAll(row.validateRequiredAttributes(["count", "max_ts"]));
    errors.addAll(row.validateTypes([
      ("count", int),
      ("max_ts", int),
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

////
// ValueAtTime
////

class ValueAtTimeToSQLRow extends DataMapper<SQLRow, ValueAtTime> {
  @override
  ValueAtTime from(SQLRow row) {
    List<String> errors = [];

    errors.addAll(row.validateRequiredAttributes(["timestamp", "lowTarget", "highTarget", "isTempTarget", "basal", "isTempBasal"]));

    errors.addAll(row.validateTypes([
      ("eid", String),
      ("timestamp", int),
      ("lowTarget", int),
      ("highTarget", int),
      ("basal", double),
      ("isf", int),
      ("cr", int),
      ("isTempProfile", int),
      ("isTempTarget", int),
      ("isTempBasal", int),
      ("profileName", String),
    ]));

    if (errors.isNotEmpty) {
      throw ArgumentError("Invalid ValueAtTime Row: $row, Errors: $errors");
    }

    return ValueAtTime(
      eid: "${row["eid"]}",
      date: DateTime.fromMillisecondsSinceEpoch(row["timestamp"] as int),
      lowTarget: row["lowTarget"] as int,
      highTarget: row["highTarget"] as int,
      basal: row["basal"] as double,
      isf: row["isf"] as int,
      cr: row["cr"] as int,
      isTempProfile: row["isTempProfile"] == 1,
      isTempBasal: row["isTempBasal"] == 1,
      isTempTarget: row["isTempTarget"] == 1,
      profileName: row["profileName"] as String,
      profilePercent: row["profilePercent"] as int,
    );
  }
}

class SQLRowToValueAtTime extends DataMapper<ValueAtTime, SQLRow> {
  @override
  SQLRow from(ValueAtTime model) {
    return SQLRow(valuesAtTimeTableName, {
      "eid": model.eid!,
      "timestamp": model.date.millisecondsSinceEpoch,
      //
      "lowTarget": model.lowTarget,
      "highTarget": model.highTarget,
      //
      "basal": model.basal,
      "isf": model.isf,
      "cr": model.cr,
      //
      "profileName": model.profileName,
      "profilePercent": model.profilePercent,
      //
      "isTempProfile": model.isTempProfile ? 1 : 0,
      "isTempBasal": model.isTempBasal ? 1 : 0,
      "isTempTarget": model.isTempTarget ? 1 : 0,
    });
  }
}
