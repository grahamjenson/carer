import 'package:carer/sql/statements/carer_db_tables.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class CarerDB {
  static final Future<CarerDB> _instance = _createInstance();
  static Future<CarerDB> get instance => _instance;

  final Database _db;
  CarerDB(this._db);

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
    print("Opening database at $path");
    var db = await openDatabase(
      path,
      version: DateTime.now()
          .millisecondsSinceEpoch, // TODO: replace this eventually with a version number
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

  /////
  // SGV
  /////

  Future<int> batchCreateOrUpdateSGVs(List<Map<String, Object>> models) async {
    if (models.any((model) => !_validateSGVMap(model))) {
      throw ArgumentError("Invalid SGV map");
    }
    return upsertQuery(_db, sgvTable.name, models, ["value", "timestamp"]);
  }

  bool _validateSGVMap(Map<String, Object> sgv) {
    if (!validateShared(sgv, ["value", "timestamp"], [int, int])) {
      return false;
    }

    if (!validateGreaterThanZero(sgv, ["value", "timestamp"])) {
      return false;
    }

    return true;
  }

  Future<int?> countSGVs({
    int after = 0,
    before = 9999999999999999,
    low = -1,
    high = 1000,
  }) async {
    var sql = """
      SELECT
        COUNT(*)
      FROM
        ${sgvsCleanView.name}
      WHERE
        timestamp >= ? AND timestamp < ? AND value >= ? AND value < ?
    """;
    // update from raw query
    return Sqflite.firstIntValue(
        await _db.rawQuery(sql, [after, before, low, high]));
  }

  Future<List<Map<String, Object?>>> sgvs(
      {int after = 0,
      before = 9999999999999999,
      low = -1,
      high = 1000,
      limit = 9000 // About a months worth
      }) async {
    // Order by most recent, then most dangerous
    var sql = """
      SELECT
        *
      FROM
        ${sgvsCleanView.name}
      WHERE
        timestamp >= ? AND timestamp < ? AND value >= ? AND value < ?
      ORDER BY 
        timestamp DESC, value ASC 
      LIMIT ?
    """;

    return _db.rawQuery(sql, [after, before, low, high, limit]);
  }

  ////
  // BOLUS
  ////

  Future<int> batchCreateOrUpdateBoluses(
      List<Map<String, Object>> models) async {
    if (models.any((model) => !_validateBolusMap(model))) {
      throw ArgumentError("Invalid Boplus map");
    }
    return upsertQuery(_db, bolusTable.name, models, ["value", "timestamp"]);
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

    return upsertQuery(_db, carbsTable.name, models, ["value", "timestamp"]);
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
}

/// Utils

Future<int> upsertQuery(Database db, String table,
    List<Map<String, Object>> models, List<String> keys) async {
  var batch = db.batch();

  var upsert = """
    INSERT INTO $table (${keys.join(", ")}) VALUES (${keys.map((e) => "?").join(", ")}) 
    ON CONFLICT(${keys.join(", ")}) DO UPDATE SET ${keys.map((e) => "$e = ?").join(", ")}
  """;

  for (var model in models) {
    var valuesList = keys.map((e) => model[e]).toList();
    valuesList.addAll(keys.map((e) => model[e]));

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
