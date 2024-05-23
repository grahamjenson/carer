import 'package:carer/sql/statements/db_tables.dart';
import 'package:carer/sql/statements/kv.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class CarerDB {
  static Future<CarerDB> _instance = _createInstance();
  static Future<CarerDB> get instance => _instance;

  final Database _db;
  CarerDB(this._db);

  static Future<CarerDB> _createInstance() async {
    var db = await openDatabaseAndCreateTables();
    return CarerDB(db);
  }

  /////
  // SGV
  /////

  Future<Map<String, Object?>?> lastSGV() async {
    // Order is highest date, then lowest value, then latest id
    // This way it is Most recent, most dangeroud.
    var sql = """
      SELECT * FROM ${DBTables.sgvTableName} ORDER BY date DESC, value ASC LIMIT 1
    """;
    return (await _db.rawQuery(sql)).firstOrNull;
  }

  Future<int> batchCreateOrUpdateSGVs(List<Map<String, Object>> sgvs) async {
    if (sgvs.any((sgv) => !_validateSVGMap(sgv))) {
      throw ArgumentError("Invalid SGV map");
    }

    var batch = _db.batch();
    var upsert =
        """INSERT INTO ${DBTables.sgvTableName} (value, date) VALUES (?, ?) 
    ON CONFLICT(value, date) DO UPDATE SET value = ?, date = ?""";

    for (var sgv in sgvs) {
      // upsert based
      batch.rawQuery(
          upsert, [sgv["value"], sgv["date"], sgv["value"], sgv["date"]]);
    }
    var results = await batch.commit(continueOnError: true);
    return results.length;
  }

  bool _validateSVGMap(Map<String, Object> sgv) {
    if (sgv.isEmpty) {
      return false;
    }
    var allowedKeys = ["value", "date"];
    if (!sgv.keys.every((element) => allowedKeys.contains(element))) {
      return false;
    }

    var value = sgv["value"];
    var date = sgv["date"];
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

  Future<int?> countSGVs(
      {int since = 0, int rangeLow = -1, int rangeHigh = 1000}) async {
    var sql = """
      SELECT
        COUNT(*)
      FROM
        ${DBTables.sgvTableName}
      WHERE
        date > ? AND value >= ? AND value <= ?
    """;
    return Sqflite.firstIntValue(
        await _db.rawQuery(sql, [since, rangeLow, rangeHigh]));
  }

  Future<List<Map<String, Object?>>> sgvsLastMins(int minsAgo) async {
    // sorted by age
    // grouped into 1 min intervals (select latest/lowest one)
    // reference previous sgv
    var sql = """
      SELECT * FROM ${DBTables.sgvTableName} WHERE date > ? ORDER BY date DESC
    """;
    return _db.rawQuery(
        sql, [DateTime.now().millisecondsSinceEpoch - minsAgo * 60 * 1000]);
  }

  ////
  //  Utilities
  ////

  // Open the database and create the tables
  static Future<Database> openDatabaseAndCreateTables() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'carer.db');
    print("Opening database at $path");
    var db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        var batch = db.batch();

        batch.execute(DBTables.sgvTable);
        batch.execute(DBTables.insulinTable);
        batch.execute(DBTables.carbsTable);
        batch.execute(DBTables.tempbasalTable);
        batch.execute(DBTables.temptargetsTable);
        batch.execute(DBTables.profileTable);

        // Also add a key value store for state and caching calculations
        batch.execute(KVTables.kvTable);

        await batch.commit();
      },
      // I am assuming these values will destroy and recreate the database on any version change.
      onDowngrade: onDatabaseDowngradeDelete,
      onUpgrade: onDatabaseDowngradeDelete,
    );

    return db;
  }

  Future<void> deleteAll() async {
    var batch = _db.batch();

    batch.delete(DBTables.sgvTableName);
    batch.delete(DBTables.insulinTableName);
    batch.delete(DBTables.carbsTableName);
    batch.delete(DBTables.tempbasalTableName);
    batch.delete(DBTables.temptargetsTableName);
    batch.delete(DBTables.profileTableName);

    // Delete KV table as well (settings are in different DB)
    batch.delete(KVTables.kvTableName);

    await batch.commit();

    return;
  }

  close() async {
    await _db.close();
    _instance = _createInstance();
  }
}
