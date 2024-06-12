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
  Map<int, Map<int, Map<String, List<Map<String, double>>>>> rmesess = {
    2: {},
    3: {},
    4: {},
    5: {},
    6: {},
    7: {},
  };
  for (var readings = 2; readings <= 7; readings++) {
    rmesess[readings] ??= {};
    for (var start = 30; start <= 576; start++) {
      var end = start + readings;
      var trainingTimes = times.sublist(start, end).toList();
      var trainingSgvs = sgvs.sublist(start, end).toList();

      for (var testReadings = 2; testReadings <= 12; testReadings++) {
        var testingTimes = times.sublist(end, end + testReadings).toList();
        var testingSgvs = sgvs.sublist(end, end + testReadings).toList();

        var b = BestMatchRegression(trainingTimes, trainingSgvs);
        rmesess[readings]![testReadings] ??= {};

        var shouldHaveBeenSelected = b.models.first;
        double minErrorVariance = double.infinity;
        for (var m in b.models) {
          var trainingDataRMSE = m.rmse;
          var (rmse, _) = m.rootMeanSquaredError(testingTimes, testingSgvs);

          if (rmse <= minErrorVariance) {
            minErrorVariance = rmse;
            shouldHaveBeenSelected = m;
          }
          rmesess[readings]![testReadings]![m.runtimeType.toString()] ??= [];

          rmesess[readings]![testReadings]![m.runtimeType.toString()]!.add({
            'trmse': trainingDataRMSE,
            'rmse': rmse,
            "selected": b.selected == m ? 1 : 0,
            "lowest": 0,
          });
          //print("${m.toString()} $rmse $trainingDataRMSE");
        }
        rmesess[readings]![testReadings]![
                shouldHaveBeenSelected.runtimeType.toString()]!
            .last['lowest'] = 1.0;
        //
      }
    }
  }

  rmesess.forEach((readings, readingsValue) {
    readingsValue.forEach((testReadings, testReadingsValue) {
      testReadingsValue.forEach((model, l) {
        // calculate the average RMSE for each model
        var totalTRMSE = 0.0;
        var totalRMSE = 0.0;
        int totalSelected = 0;
        int totalLowest = 0;
        var n = 0;
        for (var lv in l) {
          if (lv['rmse'] == null || lv['trmse'] == null) {
            continue;
          }

          double rmse = lv['rmse']!;
          double trmse = lv['trmse']!;
          bool selected = lv['selected'] == 1;
          bool lowest = lv['lowest'] == 1;
          if (rmse.isNaN ||
              trmse.isNaN ||
              rmse.isInfinite ||
              trmse.isInfinite) {
            continue;
          }

          totalTRMSE += trmse;
          totalRMSE += rmse;
          if (selected) totalSelected++;
          if (lowest) totalLowest++;
          n++;
        }

        var rmse = totalRMSE / n;
        var trmse = totalTRMSE / n;

        print(
            "$model    \t\t$readings\t$testReadings\t$n\t${dp4(trmse)}\t${dp4(rmse)}\t$totalSelected\t$totalLowest");
      });
    });
  });
  //print(rmesess);
  return true;
}

double dp4(num value) {
  if (value.isNaN || value.isInfinite) {
    return value.toDouble();
  }
  return (value * 1000.0).round() / 1000.0;
}
