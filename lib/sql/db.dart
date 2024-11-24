import 'package:carer/utils/env.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DB {
  static Future<String> getPath(String name) async {
    final databasePath = await getDatabasesPath();

    if (Env.isTest) {
      return inMemoryDatabasePath;
    }
    final path = join(databasePath, "$name.db");

    return path;
  }

  static get singleInstance => !Env.isTest;
}
