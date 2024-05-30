import 'dart:io';

import 'package:carer/sql/statements/carer_db_tables.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class CarerDB {
  static final Future<CarerDB> _instance = _createInstance();
  static Future<CarerDB> get instance => _instance;

  final Database _db;
  CarerDB(this._db);

  Database get db => _db;

  static Future<CarerDB> _createInstance() async {
    var db = await _openDatabaseAndCreateTables();
    return CarerDB(db);
  }

  static Future<String> getPath() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'carer.db');
    return path;
  }

  static Future<Database> _openDatabaseAndCreateTables() async {
    final path = await getPath();
    var version = 20;
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      version = DateTime.now().millisecondsSinceEpoch;
    }
    print("Opening database at $path");
    var db = await openDatabase(
      path,
      version: version, // TODO: replace this eventually with a version number
      onCreate: (db, version) async {
        print("Creating database at version $version");
        await dropAll(db);
        await createAll(db);
      },
      // I am assuming these values will destroy and recreate the database on any version change.
      onDowngrade: (db, oldVersion, newVersion) async {
        print("DOWNGRADING database at version $newVersion");
        await dropAll(db);
        await createAll(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        print("UPGRADING database at version $newVersion");
        await dropAll(db);
        await createAll(db);
      },
    );

    return db;
  }

  ////
  // BOLUS
  ////

  Future<int> batchCreateOrUpdateBoluses(
      List<Map<String, Object>> models) async {
    if (models.any((model) => !_validateBolusMap(model))) {
      throw ArgumentError("Invalid Boplus map");
    }
    return upsertQuery(_db, bolusTable.name, models, ["value", "timestamp"],
        ["value", "timestamp"]);
  }

  bool _validateBolusMap(Map<String, Object> bolus) {
    if (!validateShared(bolus, ["value", "timestamp"], [double, int])) {
      return false;
    }

    if (!validateGreaterThanZero(bolus, ["value", "timestamp"])) {
      return false;
    }

    return true;
  }

  Future<List<Map<String, Object?>>> boluses(
      {int after = 0,
      before = 9999999999999999,
      limit = 9000 // About a months worth
      }) async {
    // Order by most recent, then most dangerous
    var sql = """
      SELECT
        *
      FROM
        ${bolusTable.name}
      WHERE
        timestamp >= ? AND timestamp < ?
      ORDER BY 
        timestamp DESC, value ASC 
      LIMIT ?
    """;
    return _db.rawQuery(sql, [after, before, limit]);
  }

  ////
  // CARBS
  ////

  Future<int> batchCreateOrUpdateCarbs(List<Map<String, Object>> models) async {
    if (models.any((model) => !_validateCarbsMap(model))) {
      throw ArgumentError("Invalid Carbs map");
    }

    return upsertQuery(_db, carbsTable.name, models, ["value", "timestamp"],
        ["value", "timestamp"]);
  }

  bool _validateCarbsMap(Map<String, Object> bolus) {
    if (!validateShared(bolus, ["value", "timestamp"], [int, int])) {
      return false;
    }

    if (!validateGreaterThanZero(bolus, ["value", "timestamp"])) {
      return false;
    }

    return true;
  }

  Future<List<Map<String, Object?>>> carbs(
      {int after = 0,
      before = 9999999999999999,
      limit = 9000 // About a months worth
      }) async {
    // Order by most recent, then most dangerous
    var sql = """
      SELECT
        *
      FROM
        ${carbsTable.name}
      WHERE
        timestamp >= ? AND timestamp < ?
      ORDER BY 
        timestamp DESC, value ASC 
      LIMIT ?
    """;

    return _db.rawQuery(sql, [after, before, limit]);
  }

  ////
  // TREATMENTS
  ////

  Future<List<Map<String, Object?>>> concatedTreatments(
      {int after = 0,
      before = 9999999999999999,
      limit = 9000 // About a months worth
      }) async {
    // Order by most recent, then most dangerous
    var sql = """
      SELECT
        *
      FROM
        ${concatTreatmentsView.name}
      WHERE
        max_ts >= ? AND max_ts < ?
      ORDER BY 
        max_ts DESC
      LIMIT ?
    """;

    return _db.rawQuery(sql, [after, before, limit]);
  }

  ////
  // Temp Target
  ////

  Future<int> batchCreateOrUpdateTempTargets(
      List<Map<String, Object>> models) async {
    if (models.any((model) => !_validateTempTargetMap(model))) {
      throw ArgumentError("Invalid Temp Target map");
    }

    return upsertQuery(
        _db,
        temptargetsTable.name,
        models,
        ["start", "duration", "targetTop", "targetBottom"],
        ["start", "duration", "targetTop", "targetBottom"]);
  }

  bool _validateTempTargetMap(Map<String, Object> tempTarget) {
    var keys = ["start", "duration", "targetTop", "targetBottom"];

    if (!validateShared(tempTarget, keys, [int, int, int, int])) {
      return false;
    }

    if (!validateGreaterThanZero(tempTarget, keys)) {
      return false;
    }

    return true;
  }

  ////
  // Temp Basal
  ////

  Future<int> batchCreateOrUpdateTempBasals(
      List<Map<String, Object>> models) async {
    if (models.any((model) => !_validateTempBasalMap(model))) {
      throw ArgumentError("Invalid Temp Basal map");
    }

    return upsertQuery(_db, tempbasalTable.name, models,
        ["start", "duration", "value"], ["start", "value"]);
  }

  bool _validateTempBasalMap(Map<String, Object> tempTarget) {
    var keys = ["start", "duration", "value"];

    if (!validateShared(tempTarget, keys, [int, int, double])) {
      return false;
    }

    if (!validateGreaterThanZero(tempTarget, ["start", "duration"])) {
      return false;
    }

    return true;
  }

  Future<Map<String, Object?>?> tempBasalAtTime(int time) {
    var sql = """
      SELECT
        *
      FROM
        ${tempbasalTable.name}
      WHERE
        start < ? AND end > ?
      ORDER BY 
        start DESC, id DESC
      LIMIT 1
    """;

    return _db.rawQuery(sql, [time, time]).then((value) => value.firstOrNull);
  }
  ////
  // Profile
  ////

  Future<int> createOrUpdateProfile(Map<String, Object> model) async {
    if (!_validateProfileMap(model)) {
      throw ArgumentError("Invalid Profile map");
    }

    return _db.insert(profileTable.name, model,
        conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  bool _validateProfileMap(Map<String, Object> profile) {
    var keys = ["dia", "units", "timezone"] +
        crKeys +
        isfKeys +
        basalKeys +
        targetLowKeys +
        targetHighKeys;

    if (!validateNotNull(profile, keys)) {
      return false;
    }

    if (!validateAllowedKeys(profile, keys)) {
      return false;
    }

    return true;
  }

  Future<Map<String, Object?>?> profile() async {
    var sql = """
      SELECT
        *
      FROM
        ${profileTable.name}
      ORDER BY 
        timestamp DESC
      LIMIT 1
    """;

    return (await _db.rawQuery(sql)).firstOrNull;
  }
  ////
  // DB Table functions
  ////

  static Future<void> dropAll(Database db) async {
    var batch = db.batch();

    for (var table in dbTables) {
      batch.execute("DROP TABLE IF EXISTS ${table.name}");
    }

    for (var view in dbViews) {
      batch.execute("DROP VIEW IF EXISTS ${view.name}");
    }

    await batch.commit();

    return;
  }

  static Future<void> createAll(Database db) async {
    var batch = db.batch();

    for (var table in dbTables) {
      batch.execute(table.create);
    }

    for (var view in dbViews) {
      batch.execute(view.create);
    }

    await batch.commit();
  }

  Future<void> deleteAll() async {
    var batch = _db.batch();

    for (var table in dbTables) {
      batch.delete(table.name);
    }

    await batch.commit();
  }

  //// CONSTS
  static const crKeys = [
    "cr0",
    "cr1",
    "cr2",
    "cr3",
    "cr4",
    "cr5",
    "cr6",
    "cr7",
    "cr8",
    "cr9",
    "cr10",
    "cr11",
    "cr12",
    "cr13",
    "cr14",
    "cr15",
    "cr16",
    "cr17",
    "cr18",
    "cr19",
    "cr20",
    "cr21",
    "cr22",
    "cr23"
  ];

  static const isfKeys = [
    "isf0",
    "isf1",
    "isf2",
    "isf3",
    "isf4",
    "isf5",
    "isf6",
    "isf7",
    "isf8",
    "isf9",
    "isf10",
    "isf11",
    "isf12",
    "isf13",
    "isf14",
    "isf15",
    "isf16",
    "isf17",
    "isf18",
    "isf19",
    "isf20",
    "isf21",
    "isf22",
    "isf23"
  ];

  static const basalKeys = [
    "basal0",
    "basal1",
    "basal2",
    "basal3",
    "basal4",
    "basal5",
    "basal6",
    "basal7",
    "basal8",
    "basal9",
    "basal10",
    "basal11",
    "basal12",
    "basal13",
    "basal14",
    "basal15",
    "basal16",
    "basal17",
    "basal18",
    "basal19",
    "basal20",
    "basal21",
    "basal22",
    "basal23"
  ];

  static const targetLowKeys = [
    "tlow0",
    "tlow1",
    "tlow2",
    "tlow3",
    "tlow4",
    "tlow5",
    "tlow6",
    "tlow7",
    "tlow8",
    "tlow9",
    "tlow10",
    "tlow11",
    "tlow12",
    "tlow13",
    "tlow14",
    "tlow15",
    "tlow16",
    "tlow17",
    "tlow18",
    "tlow19",
    "tlow20",
    "tlow21",
    "tlow22",
    "tlow23"
  ];

  static const targetHighKeys = [
    "thigh0",
    "thigh1",
    "thigh2",
    "thigh3",
    "thigh4",
    "thigh5",
    "thigh6",
    "thigh7",
    "thigh8",
    "thigh9",
    "thigh10",
    "thigh11",
    "thigh12",
    "thigh13",
    "thigh14",
    "thigh15",
    "thigh16",
    "thigh17",
    "thigh18",
    "thigh19",
    "thigh20",
    "thigh21",
    "thigh22",
    "thigh23"
  ];
}

/// Utils

Future<int> upsertQuery(
    Database db,
    String table,
    List<Map<String, Object>> models,
    List<String> insertKeys,
    List<String> conflictKeys) async {
  var batch = db.batch();

  var upsert = """
    INSERT INTO $table (${insertKeys.join(", ")}) VALUES (${insertKeys.map((e) => "?").join(", ")}) 
    ON CONFLICT(${conflictKeys.join(", ")}) DO UPDATE SET ${insertKeys.map((e) => "$e = ?").join(", ")}
  """;

  for (var model in models) {
    var valuesList = insertKeys.map((e) => model[e]).toList();
    valuesList.addAll(insertKeys.map((e) => model[e]));

    // upsert based
    batch.rawQuery(upsert, valuesList);
  }

  var results = await batch.commit(continueOnError: true);
  return results.length;
}

bool validateShared(
    Map<String, Object> m, List<String> keys, List<Type> types) {
  if (m.isEmpty) {
    return false;
  }
  return validateNotNull(m, keys) &&
      validateAllowedKeys(m, keys) &&
      validateType(m, keys, types);
}

bool validateNotNull(Map<String, Object> m, List<String> keys) {
  for (var key in keys) {
    if (m[key] == null) {
      return false;
    }
  }
  return true;
}

bool validateAllowedKeys(Map<String, Object> m, List<String> keys) {
  return m.keys.every((element) => keys.contains(element));
}

bool validateType(Map<String, Object> m, List<String> keys, List<Type> types) {
  assert(keys.length == types.length);

  for (var i = 0; i < keys.length; i++) {
    if (m[keys[i]].runtimeType != types[i]) {
      return false;
    }
  }
  return true;
}

bool validateGreaterThanZero(Map<String, Object> m, List<String> keys) {
  for (var key in keys) {
    if (m[key] as num <= 0) {
      return false;
    }
  }
  return true;
}
