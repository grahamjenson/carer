import 'package:carer/sql/db.dart';
import 'package:carer/sql/statements/carer_db_tables.dart';
import 'package:carer/utils/logs.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common/sqflite_logger.dart';

class CarerDB {
  static final Future<CarerDB> _instance = _createInstance();
  static Future<CarerDB> get instance => _instance;

  final Database _db;
  CarerDB(this._db);

  Database get db => _db;

  static Future<String> getPath() async {
    return DB.getPath('carer');
  }

  static Future<CarerDB> _createInstance() async {
    // Set a wrapper on database factory
    var factoryWithLogs = SqfliteDatabaseFactoryLogger(
      databaseFactory,
      options: SqfliteLoggerOptions(
        log: (SqfliteLoggerEvent event) => alog("CarerDB: $event"),
        type: SqfliteDatabaseFactoryLoggerType.all,
      ),
    );

    databaseFactory = factoryWithLogs;

    var db = await _openDatabaseAndCreateTables();
    return CarerDB(db);
  }

  static int getVersion() {
    var dbScript = (dbTables).map((e) => e.create).join("\n");
    return dbScript.hashCode;
  }

  static Future<Database> _openDatabaseAndCreateTables() async {
    final path = await getPath();
    // This will grab all the db code and hash it, if it changes it drops all past stuff and replaces
    var version = getVersion();

    alog("Opening database at $path for version $version");
    var db = await openDatabase(
      path,
      version: version, // TODO: replace this eventually with a version number
      singleInstance: false,
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

    // Try WAL
    var walStr = 'PRAGMA journal_mode=WAL';
    var busyStr = 'PRAGMA busy_timeout = 2000';
    try {
      await db.execute(walStr);
      await db.execute(busyStr);
    } catch (_) {
      alog("database execute pragma failed");
    }
    try {
      await db.rawQuery(walStr);
      await db.rawQuery(busyStr);
    } catch (_) {
      alog("database rawQuery pragma failed");
    }

    alog("WAL MODE ENABLED? ${await db.rawQuery('PRAGMA journal_mode')}");

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
