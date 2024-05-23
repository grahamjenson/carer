import 'package:carer/sql/statements/db_tables.dart';
import 'package:carer/sql/statements/kv.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class CarerDB {
  static final Future<CarerDB> _instance = _createInstance();
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
    var sql = """
      SELECT * FROM sgvs ORDER BY date DESC LIMIT 1
    """;
    return (await _db.rawQuery(sql)).firstOrNull;
  }

  Future<int> batchCreateOrUpdateSGVs(List<Map<String, Object>> sgvs) async {
    var batch = _db.batch();
    var upsert = """INSERT INTO sgvs (value, date) VALUES (?, ?)
    ON CONFLICT(value, date) DO UPDATE SET value = ?, date = ?""";

    for (var sgv in sgvs) {
      // upsert based
      batch.rawInsert(
          upsert, [sgv["value"], sgv["date"], sgv["value"], sgv["date"]]);
    }
    var results = await batch.commit(continueOnError: true);
    print("ret: $results");

    return 0;
  }

  Future<int?> countSGVs({int? since, int? rangeLow, int? rangeHigh}) async {
    var sql = """
      SELECT
        COUNT(*)
      FROM
        sgvs
      WHERE
        mills > ?
    """;
    return Sqflite.firstIntValue(await _db.rawQuery(sql, [since]));
  }

  Future<List<Map<String, Object?>>> sgvsLastMins(int minsAgo) async {
    // sorted by age
    // grouped into 1 min intervals (select latest/lowest one)
    // reference previous sgv
    var sql = """
      SELECT * FROM sgvs WHERE date > ? ORDER BY date DESC
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

  Future<int> deleteAll() async {
    int ret = await _db.delete(KVTables.kvTableName);
    return ret;
  }

  close() async {
    await _db.close();
  }
}
