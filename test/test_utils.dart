import 'package:carer/models/clean_sgv.dart';
import 'package:carer/sql/carer_db.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

var dbSetup = false;
Future<void> sqfliteTestInit() async {
  if (!dbSetup) {
    dbSetup = true;
    // Initialize ffi implementation
    sqfliteFfiInit();
    // Set global factory
    databaseFactory = databaseFactoryFfi;
  }
}

void agroup(Object description, void Function() body, {dynamic skip, int? retry}) {
  group(description, () {
    setUp(() async {
      await sqfliteTestInit();
      await (await CarerDB.instance).deleteAll();

      CleanSGV.setupSQLSignals();
      CleanSGV.setupSQLSignals();
    });
    body();
  }, skip: skip, retry: retry);
}

double dp4(double x) {
  return (x * 1000).round() / 1000;
}

double epoch(DateTime d) {
  return d.millisecondsSinceEpoch.toDouble();
}
