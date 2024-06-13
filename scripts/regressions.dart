import 'dart:convert';
import 'dart:io';

import 'package:clock/clock.dart';
import 'package:collection/collection.dart';

import "copied/regressions.dart";

void main() async {
  var entries = await parseJsonFromFile("data.json");

  //sort by first element
  entries.sort((a, b) => b.$1.compareTo(a.$1));
  entries = entries.map((e) => (e.$1, e.$2.round().toDouble())).toList();

  print(entries.length);

  final double mimnutesFromEpochToLastWeek =
      clock.now().subtract(const Duration(days: 7)).millisecondsSinceEpoch /
          60000;

  double fnX(num x) =>
      (x / 60000.0).round().toDouble() - mimnutesFromEpochToLastWeek;
  int fnRX(double x) =>
      (x * 60000.0).toInt() + mimnutesFromEpochToLastWeek.toInt();

  List<double> sgvs = [];
  List<double> times = [];
  for (var entry in entries) {
    times.add(fnX(entry.$1.millisecondsSinceEpoch.toDouble()));
    sgvs.add(entry.$2.toInt().toDouble());
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

  // Number of tests
  // When low and linear predicts going up, does it go up and just miss?
  // When high and linear predicts going down, does it go down and just miss?
  // Using this system and understanding the error variance what are the safe guarged we should place
  // four days
  var numOfTests = 12 * 24 * 7;

  for (var readings = 2; readings <= 7; readings++) {
    rmesess[readings] ??= {};
    // Jump further by 5 each time
    for (var start = 0; start < numOfTests * 2; start += 2) {
      var end = start + readings;
      var trainingTimes = times.sublist(start, end).toList();
      var trainingSgvs = sgvs.sublist(start, end).toList();
      //print("TRAIN $trainingTimes $trainingSgvs");

      for (var testReadings = 1; testReadings <= 12; testReadings++) {
        var testingTimes = times.sublist(end, end + testReadings).toList();
        var testingSgvs = sgvs.sublist(end, end + testReadings).toList();

        //print("TEST $testingTimes $testingSgvs");
        var b = BestMatchRegression(
            trainingTimes.reversed.toList(), trainingSgvs.reversed.toList());

        rmesess[readings]![testReadings] ??= {};

        var shouldHaveBeenSelected = b.models.first;
        double minErrorVariance = double.infinity;
        for (var m in b.models) {
          var modelName = m.runtimeType.toString();
          var (trainingDataRMSE, _) =
              m.rootMeanSquaredError(trainingTimes, trainingSgvs);

          var (rmse, preds) = m.rootMeanSquaredError(testingTimes, testingSgvs);
          var high = 0;
          var low = 0;
          for (var i = 0; i < testingSgvs.length; i++) {
            if (testingSgvs[i] > preds[i]) {
              high++;
            } else {
              low++;
            }
          }

          if (testReadings == 10) {
            if (trainingSgvs.last < 72 && preds[3] > 90) {
              // print(
              //     " AAA $modelName $readings, $testReadings, $high, $low ${trainingSgvs.last} ${testingSgvs[3]} ${preds[3]}");
            }
          }
          if (rmse <= minErrorVariance) {
            minErrorVariance = rmse;
            shouldHaveBeenSelected = m;
          }
          rmesess[readings]![testReadings]![modelName] ??= [];

          rmesess[readings]![testReadings]![modelName]!.add({
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

  Map<String, List<List<double>>> bestTrainingSet = {};

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

        var modelName = model.replaceFirst("Regression", "");
        var modelNameTrainingSet =
            "r$modelName(${readings.toString().padLeft(2, "0")})";
        var modelNameTS =
            "$modelName(${testReadings.toString().padLeft(2, "0")})";

        bestTrainingSet[modelName] ??= [[], [], [], [], [], []];
        bestTrainingSet[modelName]![readings - 2].add(trmse);
        print(
            "$model,$readings,$testReadings,$n,${dp4(trmse)},${dp4(rmse)},$totalSelected,$totalLowest");
      });
    });
  });
  //print(rmesess);
  print("");
  print("");
  var keys = bestTrainingSet.keys.sorted((a, b) {
    return a.compareTo(b);
  });
  for (var m in keys) {
    var ds = bestTrainingSet[m]!;
    print("$m,${ds.map((e) => (e).average).join(",")}");
  }

  return true;
}

double dp4(num value) {
  if (value.isNaN || value.isInfinite) {
    return value.toDouble();
  }
  return (value * 1000.0).round() / 1000.0;
}

Future<List<(DateTime, double)>> parseJsonFromFile(String filePath) async {
  try {
    // Read the file
    final file = File(filePath);
    final jsonString = await file.readAsString();

    // Decode the JSON string
    final List<dynamic> jsonData = jsonDecode(jsonString);

    //     {
    //   "time": "2024-05-31T04:31:25Z",
    //   "type": "cbg",
    //   "value": 113.9999511815
    // },

    List<(DateTime, double)> sgvs = [];

    for (var i in jsonData) {
      if (i['type'] == 'cbg') {
        sgvs.add((DateTime.parse(i['time']), i['value']));
      }
    }
    return sgvs;
  } catch (e) {
    // Handle errors (e.g., file not found, invalid JSON)
    print('Error reading or parsing the file: $e');
    return [];
  }
}
