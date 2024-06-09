import 'dart:io';
import 'dart:math';

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
    var name = 'carer.db';
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      // TODO make database in memory for tests
      name = 'test_carer_${Random().nextInt(999999999)}.db';
    }
    final path = join(databasePath, name);
    return path;
  }

  static Future<Database> _openDatabaseAndCreateTables() async {
    final path = await getPath();
    // TODO hash all database table code to single value to set version for
    var version = 7;

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
      select a.id as a_id, a.start as a_start, b.start as b_start from $table as a join $table as b on a.start < b.start and b.start < a.end
    )
    update $table set duration = (b_start - a_start)/1000 from badData where id = a_id 
    ''';
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
