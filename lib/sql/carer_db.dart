import 'package:carer/sql/statements/carer_db_tables.dart';
import 'package:carer/sql/statements/kv.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class CarerDB {
  static Future<CarerDB> _instance = _createInstance();
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
      version: 10,
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

  Future<int> batchCreateOrUpdateSGVs(List<Map<String, Object>> sgvs) async {
    if (sgvs.any((sgv) => !_validateSVGMap(sgv))) {
      throw ArgumentError("Invalid SGV map");
    }

    var batch = _db.batch();
    var upsert =
        """INSERT INTO ${DBTables.sgvTableName} (value, timestamp) VALUES (?, ?) 
    ON CONFLICT(value, timestamp) DO UPDATE SET value = ?, timestamp = ?""";

    for (var sgv in sgvs) {
      // upsert based
      batch.rawQuery(upsert,
          [sgv["value"], sgv["timestamp"], sgv["value"], sgv["timestamp"]]);
    }
    var results = await batch.commit(continueOnError: true);
    return results.length;
  }

  bool _validateSVGMap(Map<String, Object> sgv) {
    if (sgv.isEmpty) {
      return false;
    }
    var allowedKeys = ["value", "timestamp"];
    if (!sgv.keys.every((element) => allowedKeys.contains(element))) {
      return false;
    }

    var value = sgv["value"];
    var date = sgv["timestamp"];
    if (value == null || date == null) {
      return false;
    }
    if (value is! int || date is! int) {
      return false;
    }
    if (value < 0 || value > 1000) {
      return false;
    }
    if (date < 0) {
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
        ${DBTables.sgvTableName}
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
        ${DBTables.sgvTableName}
      WHERE
        timestamp >= ? AND timestamp < ? AND value >= ? AND value < ?
      ORDER BY 
        timestamp DESC, value ASC 
      LIMIT ?
    """;
    // TODO update from raw query
    return _db.rawQuery(sql, [after, before, low, high, limit]);
  }

  ////
  // Testing functions
  ////

  static Future<void> dropAll(Database db) async {
    var batch = db.batch();

    batch.execute("DROP TABLE IF EXISTS ${DBTables.sgvTableName}");

    batch.execute("DROP TABLE IF EXISTS ${DBTables.insulinTableName}");
    batch.execute("DROP TABLE IF EXISTS ${DBTables.carbsTableName}");
    batch.execute("DROP TABLE IF EXISTS ${DBTables.tempbasalTableName}");
    batch.execute("DROP TABLE IF EXISTS ${DBTables.temptargetsTableName}");
    batch.execute("DROP TABLE IF EXISTS ${DBTables.profileTableName}");

    batch.execute("DROP TABLE IF EXISTS ${KVTables.kvTableName}");

    await batch.commit();

    return;
  }

  static Future<void> createAll(Database db) async {
    var batch = db.batch();

    batch.execute(DBTables.sgvTable);
    batch.execute(DBTables.sgvIndex);

    batch.execute(DBTables.insulinTable);
    batch.execute(DBTables.carbsTable);
    batch.execute(DBTables.tempbasalTable);
    batch.execute(DBTables.temptargetsTable);
    batch.execute(DBTables.profileTable);

    // Also add a key value store for state and caching calculations
    batch.execute(KVTables.kvTable);

    await batch.commit();
  }

  recreate() async {
    await _db.close();
    await deleteDatabase(await getPath());
    _instance = _createInstance();
  }
}
