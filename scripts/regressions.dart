import 'dart:io';

import 'package:clock/clock.dart';

import "copied/nsclient.dart";
import "copied/regressions.dart";

void main() async {
  Map<String, String> env = Platform.environment;
  var nsURL = env["NS_URL"]!;
  var nsToken = env["TOKEN"]!;

  var entries = await NSClient().getEntries(nsURL, nsToken, 12 * 48);

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

  var trainingReadings = 5;
  var b = BestMatchRegression(times.take(trainingReadings).toList(),
      sgvs.take(trainingReadings).toList());
}
