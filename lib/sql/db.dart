import 'package:carer/utils/env.dart';
import 'package:carer/utils/logs.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DB {
  static Future<String> getPath(String name) async {
    final databasePath = await getDatabasesPath();

    if (Env.isTest) {
      return inMemoryDatabasePath;
    }
    final path = join(databasePath, "$name.db");
    print("DBPath: Using database path: $path");
    return path;
  }

  static get singleInstance => !Env.isTest;

  static Future<void> setPragma(String name, Database db) async {
    var walStr = 'PRAGMA journal_mode=WAL';
    var busyStr = 'PRAGMA busy_timeout=1000';
    try {
      await db.rawQuery(walStr);
      await db.rawQuery(busyStr);
    } catch (e) {
      print("$name database pragma failed $e");
      alog("$name database pragma failed $e");
    }

    alog("$name database ${await db.rawQuery('PRAGMA journal_mode')} ${await db.rawQuery('PRAGMA busy_timeout')}");
  }
}
