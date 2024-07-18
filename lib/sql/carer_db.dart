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
    var hashCode = (dbTables + dbViews).join("").hashCode;
    var version = hashCode;

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
  // Fun queries
  ////

  Future<int> fixBadTempTargets() {
    return _db.rawUpdate(fixBadTable(temptargetsTableName));
  }

  Future<int> fixBadTempBasals() {
    return _db.rawUpdate(fixBadTable(tempbasalTableName));
  }

  String fixBadTable(table) {
    // This query finds temp basals and temp targets which seem to be incorrect (for some reason)
    // TODO limit this to a time scope, no point joining tables months ago
    return '''
    with badData  as (
      select a.id as a_id, (b.start -a.start)/1000 as nd from $table as a join $table as b on a.start < b.start and b.start < a.end order by nd desc
    )
    update $table set duration = nd from badData where id = a_id 
    ''';
  }
  ////
  // DB Table functions
  ////

  static Future<void> dropAll(Database db) async {
    // Get the list of all tables in the database
    final List<Map<String, dynamic>> all = await db.rawQuery(
      "SELECT name, type FROM sqlite_master WHERE name NOT LIKE 'sqlite_%';",
    );

    print(all);

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
}
