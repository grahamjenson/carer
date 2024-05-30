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
    var version = 23;
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
