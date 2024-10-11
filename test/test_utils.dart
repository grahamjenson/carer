import 'package:carer/sql/carer_db.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<void> sqfliteTestInit() async {
  // Initialize ffi implementation
  sqfliteFfiInit();
  // Set global factory
  databaseFactory = databaseFactoryFfi;
  var db = await CarerDB.instance;
  print("VERSION ${await db.db.getVersion()}");
  print(db.db.path);
}

double dp4(double x) {
  return (x * 1000).round() / 1000;
}

double epoch(DateTime d) {
  return d.millisecondsSinceEpoch.toDouble();
}
