import 'package:carer/models/clean_sgv.dart';
import 'package:carer/models/sql/profile.dart';
import 'package:carer/models/sql/sgv.dart';
import 'package:carer/models/treatment_group.dart';
import 'package:carer/models/valueAtTime.dart';
import 'package:carer/sql/carer_db.dart';
import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

bool dbSetup = false;
Future<void> setupDB() async {
  if (dbSetup) {
    return;
  }
  dbSetup = true;
  // Initialize ffi implementation
  sqfliteFfiInit();
  // Set global factory
  databaseFactory = databaseFactoryFfi;
}

bool signalSetup = false;
Future<void> setupSignals() async {
  if (signalSetup) {
    return;
  }
  signalSetup = true;
  await CleanSGV.setupSQLSignals();
  await Profile.setupSQLSignals();
  await Treatment.setupSQLSignals();
  await ValueAtTime.setupSQLSignals();
  await SGV.setupSQLSignals();
}

// Not sure of the point of this right now
// cleanSignals() {
//   SQLToBolus().writeSignal.value = 0;
//   SQLToCarbs().writeSignal.value = 0;
//   SQLToProfile().writeSignal.value = 0;
//   SQLToSGV().writeSignal.value = 0;
//   SQLToTempBasal().writeSignal.value = 0;
//   SQLToTempTarget().writeSignal.value = 0;
// }

void agroup(Object description, void Function() body, {dynamic skip, int? retry}) {
  group(description, () {
    setUp(() async {
      await setupDB();
      await setupSignals();

      // Delete all data before each test
      await (await CarerDB.instance).deleteAll();
    });
    body();
  }, skip: skip, retry: retry);
}

void atest(
  Object description,
  Function body, {
  String? testOn,
  Timeout? timeout,
  dynamic skip,
  dynamic tags,
  Map<String, dynamic>? onPlatform,
  int? retry,
}) {
  assert(body is Future Function(DateTime) || body is Future Function());

  test(description, () async {
    DateTime now = DateTime(2020, 1, 1, 12);
    await withClock(Clock.fixed(now), () async {
      if (body is Future Function(DateTime)) {
        await body(now);
      } else {
        await body();
      }
    });
  }, testOn: testOn, timeout: timeout, skip: skip, tags: tags, onPlatform: onPlatform, retry: retry);
}

double dp4(double x) {
  return (x * 1000).round() / 1000;
}

double epoch(DateTime d) {
  return d.millisecondsSinceEpoch.toDouble();
}

int minTime(int min) {
  if (min == 0) return 1; // has to be above 1
  return 1000 * 60 * min;
}

// Static stuff
Duration min1 = const Duration(minutes: 1);
Duration min5 = const Duration(minutes: 5);
Duration hour48 = const Duration(hours: 48);
