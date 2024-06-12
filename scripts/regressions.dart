import 'dart:io';

import 'package:clock/clock.dart';

import "copied/nsclient.dart";
import "copied/regressions.dart";

void main() async {
  Map<String, String> env = Platform.environment;
  var nsURL = env["NS_URL"]!;
  var nsToken = env["TOKEN"]!;

  var entries = await NSClient().getEntries(nsURL, nsToken, 12 * 24 * 14);
  print(entries.entries.length);

  final double mimnutesFromEpochToLastWeek =
      clock.now().subtract(const Duration(days: 7)).millisecondsSinceEpoch /
          60000;

  double fnX(num x) =>
      (x / 60000.0).round().toDouble() - mimnutesFromEpochToLastWeek;
  int fnRX(double x) =>
      (x * 60000.0).toInt() + mimnutesFromEpochToLastWeek.toInt();

  List<double> sgvs = [];
  List<double> times = [];
  for (var entry in entries.entries) {
    if (entry.sgv == null) {
      continue;
    }
    times.add(fnX(entry.date.millisecondsSinceEpoch.toDouble()));
    sgvs.add(entry.sgv!.toDouble());
  }

  // Variables
  // training readings
  // check real values

  printTest(times, sgvs);
}

bool printTest(List<double> times, List<double> sgvs) {
  for (var readings = 2; readings < 7; readings++) {
    for (var start = 30; start < 300; start++) {
      var end = start + readings;
      var trainingTimes = times.sublist(start, end).toList();
      var trainingSgvs = sgvs.sublist(start, end).toList();

      var testingTimes = times.sublist(end, end + 12).toList();
      var testingSgvs = sgvs.sublist(end, end + 12).toList();

      var b = BestMatchRegression(trainingTimes, trainingSgvs);

      for (var m in b.models) {
        var trainingDataRMSE = m.rmse;
        var (rmse, _) = m.rootMeanSquaredError(testingTimes, testingSgvs);
        print("${m.toString()} $rmse $trainingDataRMSE");
      }
      print("--------");
    }
  }
  return true;
}
