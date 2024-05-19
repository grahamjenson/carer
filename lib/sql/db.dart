import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

////
// READINGS
////

// create glucose
createSGVTable(Batch batch) {
  batch.execute('''
    CREATE TABLE sgvs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      value REAL,
      date TEXT
    )
  ''');
}

////
// TREATMENTS
////

// create insulin
createInsulinTable(Batch batch) {
  batch.execute('''
    CREATE TABLE insulin (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      value REAL,
      date TEXT
    )
  ''');
}

// create carbs
createCarbsTable(Batch batch) {
  batch.execute('''
    CREATE TABLE carbs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      value REAL,
      date TEXT
    )
  ''');
}

// create basal
createTempBasalTable(Batch batch) {
  batch.execute('''
    CREATE TABLE tempbasal (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      value REAL,
      date TEXT
    )
  ''');
}

// create targets
createTempTargetsTable(Batch batch) {
  batch.execute('''
    CREATE TABLE temptargets (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      value REAL,
      date TEXT
    )
  ''');
}

////
// PROFILE
////

// create profile table
createProfileTable(Batch batch) {
  // Should we denormalize and have [24] array for each type of basal, carb ratio, etc?
  // Yes, then we can do comparisons easier
  batch.execute('''
    CREATE TABLE profile (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT,
      age INTEGER,
      weight REAL,
      height REAL
    )
  ''');
}

////
// State Information
////

// create state table
createStateTable(Batch batch) {
  batch.execute('''
    CREATE TABLE state (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      value TEXT,
      date TEXT
    )
  ''');
}

// Open the database and create the tables
Future<Database> openDatabaseAndCreateTables() async {
  final databasePath = await getDatabasesPath();
  final path = join(databasePath, 'carer.db');
  int version = 1;
  print("Opening database at $path");
  var db = await openDatabase(
    path,
    version: version,
    onCreate: (db, version) async {
      var batch = db.batch();
      // Create Tables
      createSGVTable(batch);
      createInsulinTable(batch);
      createCarbsTable(batch);
      createTempBasalTable(batch);
      createTempTargetsTable(batch);
      createProfileTable(batch);
      createStateTable(batch);
      await batch.commit();
    },
    onDowngrade: onDatabaseDowngradeDelete,
    onUpgrade: onDatabaseDowngradeDelete,
  );

  return db;
}
