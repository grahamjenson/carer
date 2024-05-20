import 'package:carer/sql/statements/db_tables.dart';
import 'package:carer/sql/statements/kv.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class CarerDB {
  final Database db;
  CarerDB(this.db);

  static Future<CarerDB> create() async {
    final db = await openDatabaseAndCreateTables();
    return CarerDB(db);
  }

  // Open the database and create the tables
  static Future<Database> openDatabaseAndCreateTables() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'carer.db');
    print("Opening database at $path");
    var db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        var batch = db.batch();

        batch.execute(DBTables.sgvTable);
        batch.execute(DBTables.insulinTable);
        batch.execute(DBTables.carbsTable);
        batch.execute(DBTables.tempbasalTable);
        batch.execute(DBTables.temptargetsTable);
        batch.execute(DBTables.profileTable);

        // Also add a key value store for state and caching calculations
        batch.execute(KVTables.kvTable);

        await batch.commit();
      },
      // I am assuming these values will destroy and recreate the database on any version change.
      onDowngrade: onDatabaseDowngradeDelete,
      onUpgrade: onDatabaseDowngradeDelete,
    );

    return db;
  }
}
