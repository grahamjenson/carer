import 'package:carer/mappers/sql/events.dart';
import 'package:carer/mappers/sql/sgv.dart';
import 'package:carer/models/clean_sgv.dart';
import 'package:carer/models/sql/profile.dart';
import 'package:carer/models/sql/sgv.dart';
import 'package:carer/models/treatment_group.dart';
import 'package:carer/models/valueAtTime.dart';
import 'package:carer/sql/carer_db.dart';
import 'package:carer/utils/futures.dart';
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
  await SQLToEvents().setupSQLSignals();
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
    await withClock(Clock.fixed(overrideNow), () async {
      if (body is Future Function(DateTime)) {
        await body(overrideNow);
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
DateTime overrideNow = DateTime(2020, 1, 1, 12);

Duration min0 = const Duration(minutes: 0);
Duration min1 = const Duration(minutes: 1);
Duration min5 = const Duration(minutes: 5);
Duration min10 = const Duration(minutes: 10);
Duration min15 = const Duration(minutes: 15);
Duration min20 = const Duration(minutes: 20);

Duration hour1 = const Duration(hours: 1);
Duration hour24 = const Duration(hours: 24);
Duration hour36 = const Duration(hours: 36);
Duration hour48 = const Duration(hours: 48);

// List<(value, ago)>
int eid = 0;
Future<int> createSVGs(List<(int, Duration)> values, {DateTime? now}) async {
  return createSVGsWithEIDs(values.map((v) => ("${eid++}", v.$1, v.$2)).toList(), now: now);
}

// List<(eid, value, ago)>
Future<int> createSVGsWithEIDs(List<(String, int, Duration)> values, {DateTime? now}) async {
  now ??= overrideNow;

  var ret = 0;
  await waitForSignalChange(() async {
    ret = await SQLToSGV().saveAll(values.map((v) => SGV(value: v.$2, date: now!.subtract(v.$3), eid: v.$1)).toList());
  }, [CleanSGV.lastSGV, SGV.last2Days]);

  return ret;
  // wait for CleanSGV signals to update
}

typedef SignalChangeFunction = Future Function();

// Because the SignalAssign for a bunch of signals are asyncrhnous we need to wait for them to complete
// The easiest way is to just loop for a little bit waiting for the signals lastSet date to change
// This will wait for a bunch of Signals to complete
// If I was fancy you could just input some signals and find all dpenedent signals, but that is a lot of complicated work
// I will leave that fun for later
waitForSignalChange(SignalChangeFunction fn, List<ASignal> signals, {Duration? timeout}) async {
  signals.map((e) => e.value).toList();

  timeout ??= const Duration(milliseconds: 100);
  List<DateTime> lastSet = signals.map((e) => e.lastSet).toList();

  await fn();

  // We check 5 times
  int loops = 10;
  int delayTime = timeout.inMilliseconds ~/ loops;

  for (int loop = 0; loop < loops; loop++) {
    List<DateTime> newLastSet = signals.map((e) => e.lastSet).toList();
    var allDifferent = true;
    for (int i = 0; i < signals.length; i++) {
      if (lastSet[i] == newLastSet[i]) {
        allDifferent = false;
      }
    }

    if (allDifferent) {
      return;
    }
    await Future.delayed(Duration(milliseconds: delayTime));
  }

  print("Didnt get signal change");
}
