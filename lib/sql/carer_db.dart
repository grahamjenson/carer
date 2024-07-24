import 'dart:math';

import 'package:carer/sql/statements/carer_db_tables.dart';
import 'package:carer/utils/env.dart';
import 'package:carer/utils/logs.dart';
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
    var name = 'carer.db';
    if (Env.isTest) {
      // TODO make database in memory for tests
      name = 'test_carer_${Random().nextInt(999999999)}.db';
    }
    final path = join(databasePath, name);
    return path;
  }

  static Future<Database> _openDatabaseAndCreateTables() async {
    final path = await getPath();
    // This will grab all the db code and hash it, if it changes it drops all past stuff and replaces
    var dbScript = (dbTables + dbViews).map((e) => e.create).join("\n");
    var version = dbScript.hashCode;

    alog("Opening database at $path for version $version");
    var db = await openDatabase(
      path,
      version: version, // TODO: replace this eventually with a version number
      onCreate: (db, version) async {
        alog("Creating database at version $version");
        await dropAll(db);
        await createAll(db);
      },
      // I am assuming these values will destroy and recreate the database on any version change.
      onDowngrade: (db, oldVersion, newVersion) async {
        alog("DOWNGRADING database at version $newVersion (from version $oldVersion)");
        await dropAll(db);
        await createAll(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        alog("UPGRADING database at version $newVersion (from version $oldVersion)");
        await dropAll(db);
        await createAll(db);
      },
    );

    return db;
  }

  ////
  // DB Table functions
  ////

  static Future<void> dropAll(Database db) async {
    // Get the list of all tables in the database
    final List<Map<String, dynamic>> all = await db.rawQuery(
      "SELECT name, type FROM sqlite_master WHERE name NOT LIKE 'sqlite_%';",
    );

    // Use a batch to execute multiple commands at once
    var batch = db.batch();

    for (var table in all) {
      if (table['type'] != 'table') continue;
      batch.execute("DROP TABLE IF EXISTS ${table['name']}");
    }

    for (var view in all) {
      if (view['type'] != 'view') continue;
      batch.execute("DROP VIEW IF EXISTS ${view['name']}");
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

  static int logCounter = 0;
  static Future<bool> writeLog(DateTime dt, String message, int level) async {
    var cdb = await CarerDB.instance;
    var db = cdb.db;

    logCounter++;
    // Write the log
    db.insert(logsTableName, {"timestamp": dt.millisecondsSinceEpoch, "message": message, "level": level});
    // count the writes, every few thousand writes truncate the end of the table
    if (logCounter % 10000 == 0) {
      db.delete(logsTableName, where: "where timestamp < ?", whereArgs: [dt.subtract(const Duration(days: 2)).millisecondsSinceEpoch]);
    }

    return true;
  }
}
