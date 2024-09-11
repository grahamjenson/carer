import 'dart:math';

import 'package:carer/utils/env.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DB {
  static Future<String> getPath(String name) async {
    final databasePath = await getDatabasesPath();

    if (Env.isTest) {
      // TODO make database in memory for tests
      name = 'test_${name}_${Random().nextInt(999999999)}.db';
    }
    final path = join(databasePath, "$name.db");
    return path;
  }
}
