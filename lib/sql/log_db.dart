import 'dart:isolate';

import 'package:carer/sql/db.dart';
import 'package:sqflite/sqflite.dart';

const String logsTableName = 'logs';
const logsCreateTable = '''
    CREATE TABLE logs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      level TEXT,
      thread TEXT,
      timestamp INTEGER,
      datetime TEXT GENERATED ALWAYS AS (datetime(timestamp / 1000, 'unixepoch')) VIRTUAL,
      message TEXT
    )
  ''';

class LogDB {
  static final Future<LogDB> _instance = _createInstance();
  static Future<LogDB> get instance => _instance;

  final Database _db;
  LogDB(this._db);

  Database get db => _db;

  // Constructor
  static Future<LogDB> _createInstance() async {
    final db = await openDatabaseAndCreateTables();
    var logDB = LogDB(db);

    return logDB;
  }

  static Future<String> getPath() async {
    return DB.getPath("log");
  }

  // Open the database and create the tables
  static Future<Database> openDatabaseAndCreateTables() async {
    final path = await getPath();
    var db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute(logsCreateTable);
        await truncateLogs(db);
      },
    );

    return db;
  }

  static int logCounter = 0;
  static int maxLogRows = 10000;

  static Future<bool> writeLog(DateTime dt, String message, int level) async {
    var ldb = await LogDB.instance;
    var db = ldb.db;

    return writeLogToDB(db, dt, message, level);
  }

  static Future<bool> writeLogToDB(Database db, DateTime dt, String message, int level) async {
    logCounter++;
    // Write the log
    await db.insert(logsTableName, {
      "timestamp": dt.millisecondsSinceEpoch,
      "message": message,
      "level": level,
      "thread": Isolate.current.debugName,
    });

    if (logCounter % maxLogRows == 0) {
      // count the writes, every few thousand writes truncate the end of the table
      truncateLogs(db);
    }

    return true;
  }

  static truncateLogs(Database db) async {
    await db.execute("DELETE FROM $logsTableName WHERE id < (SELECT MAX(id) - $maxLogRows FROM $logsTableName)");
  }
}
