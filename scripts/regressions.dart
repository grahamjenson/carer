import 'dart:convert';
import 'dart:io';

import "implregressions.dart";

final double mimnutesFromEpochToLastWeek =
    DateTime(2024).subtract(const Duration(days: 100)).millisecondsSinceEpoch /
        60000;

double fnX(num x) {
  var ret = ((x / 60000.0).round().toDouble() - mimnutesFromEpochToLastWeek)
      .round()
      .toDouble();
  return ret;
}

int fnRX(double x) =>
    (x * 60000.0).toInt() + mimnutesFromEpochToLastWeek.toInt();

void main() async {
  // data.json is a tide pool dump of JSON data
  var entries = await parseJsonFromFile("data.json");

  entries = entries.toSet().toList();
  print(entries.length);

  //sort by first element
  entries.sort((a, b) => b.$1.compareTo(a.$1));
  entries = entries.map((e) => (e.$1, e.$2.round().toDouble())).toList();

  List<double> sgvs = [];
  List<double> times = [];
  for (var entry in entries) {
    times.add(fnX(entry.$1.millisecondsSinceEpoch.toDouble()));
    sgvs.add(entry.$2.toInt().toDouble());
  }

  // 278973.0
  // 21047
  // Variables
  // training readings
  // check real values

  printTest(times, sgvs);
}

bool printTest(List<double> times, List<double> sgvs) {
  Map<int, Map<int, Map<String, List<Map<String, double>>>>> rmesess = {
    -18: {},
    0: {},
    18: {},
  };

  // Number of tests
  // When low and linear predicts going up, does it go up and just miss?
  // When high and linear predicts going down, does it go down and just miss?
  // Using this system and understanding the error variance what are the safe guarged we should place
  // four days
  var numOfTests = 12 * 24 * 80;
  var readings = 5;

  for (var start = 0; start < numOfTests; start++) {
// Jump further by 5 each time
    var end = start + readings;
    var trainingTimes = times.sublist(start, end).toList();
    var trainingSgvs = sgvs.sublist(start, end).toList();
    //print("TRAIN $trainingTimes $trainingSgvs");

    for (var testReadings = 1; testReadings <= 6; testReadings++) {
      var testingTimes =
          times.sublist(end + testReadings - 1, end + testReadings).toList();
      var testingSgvs =
          sgvs.sublist(end + testReadings - 1, end + testReadings).toList();

      assert(testingSgvs.length == 1);
      // print(testingSgvs);
      var testSVG = testingSgvs.first;

      //print("TEST $testingTimes $testingSgvs");
      var b = BestMatchRegression(
          trainingTimes.reversed.toList(), trainingSgvs.reversed.toList());

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

        for (var lowHighDiff in [(0, 0)]) {
          var (lowDiff, highDiff) = lowHighDiff;

          rmesess[lowDiff] ??= {};
          rmesess[lowDiff]![testReadings] ??= {};

          var isLow = trainingSgvs.last < 72;
          var isHigh = trainingSgvs.last > 180;
          var isNormal = !isLow && !isHigh;
          var isGoingToBeLow = testSVG < 72;
          var isGoingToBeHigh = testSVG > 180;
          var isGoingToBeNormal = !isGoingToBeLow && !isGoingToBeHigh;

          var predictedLow = preds.last < 72 + lowDiff;
          var predictedHigh = preds.last > 180 + highDiff;
          var predictedNormal = !predictedLow && !predictedHigh;

          // Work Out Predicted Low/High Proabability to be True
          if (isLow) {}
          if (rmse <= minErrorVariance) {
            minErrorVariance = rmse;
            shouldHaveBeenSelected = m;
          }
          rmesess[lowDiff]![testReadings]![modelName] ??= [];

          //simple implementations of smart snooze and predictive low

          var (predictAlarm, willAlarm) = predictiveAlarm(
              isLow,
              isHigh,
              isNormal,
              isGoingToBeLow,
              isGoingToBeHigh,
              isGoingToBeNormal,
              predictedLow,
              predictedHigh,
              predictedNormal);

          var (predictSnoozeLow, willSnoozeLow) = smartSnoozeLow(
              isLow,
              isHigh,
              isNormal,
              isGoingToBeLow,
              isGoingToBeHigh,
              isGoingToBeNormal,
              predictedLow,
              predictedHigh,
              predictedNormal);

          var (predictSnoozeHigh, willSnoozeHigh) = smartSnoozeHigh(
              isLow,
              isHigh,
              isNormal,
              isGoingToBeLow,
              isGoingToBeHigh,
              isGoingToBeNormal,
              predictedLow,
              predictedHigh,
              predictedNormal);

          var predictAlarmTP = isNormal && predictAlarm && willAlarm;
          var predictAlarmFP = isNormal && predictAlarm && !willAlarm;
          var predictAlarmFN = isNormal && !predictAlarm && willAlarm;
          var predictAlarmTN = isNormal && !predictAlarm && !willAlarm;

          var predictSnoozeLowTP = isLow && predictSnoozeLow && willSnoozeLow;
          var predictSnoozeLowFP = isLow && predictSnoozeLow && !willSnoozeLow;
          var predictSnoozeLowFN = isLow && !predictSnoozeLow && willSnoozeLow;
          var predictSnoozeLowTN = isLow && !predictSnoozeLow && !willSnoozeLow;

          var predictSnoozeHighTP =
              isHigh && predictSnoozeHigh && willSnoozeHigh;
          var predictSnoozeHighFP =
              isHigh && predictSnoozeHigh && !willSnoozeHigh;
          var predictSnoozeHighFN =
              isHigh && !predictSnoozeHigh && willSnoozeHigh;
          var predictSnoozeHighTN =
              isHigh && !predictSnoozeHigh && !willSnoozeHigh;

          rmesess[lowDiff]![testReadings]![modelName]!.add({
            'trmse': trainingDataRMSE,
            'rmse': rmse,
            "selected": b.selected == m ? 1 : 0,
            "lowest": 0,
            "predictAlarmTP": predictAlarmTP ? 1 : 0,
            "predictAlarmFP": predictAlarmFP ? 1 : 0,
            "predictAlarmFN": predictAlarmFN ? 1 : 0,
            "predictAlarmTN": predictAlarmTN ? 1 : 0,
            "predictSnoozeLowTP": predictSnoozeLowTP ? 1 : 0,
            "predictSnoozeLowFP": predictSnoozeLowFP ? 1 : 0,
            "predictSnoozeLowFN": predictSnoozeLowFN ? 1 : 0,
            "predictSnoozeLowTN": predictSnoozeLowTN ? 1 : 0,
            "predictSnoozeHighTP": predictSnoozeHighTP ? 1 : 0,
            "predictSnoozeHighFP": predictSnoozeHighFP ? 1 : 0,
            "predictSnoozeHighFN": predictSnoozeHighFN ? 1 : 0,
            "predictSnoozeHighTN": predictSnoozeHighTN ? 1 : 0,
            "isLow": isLow ? 1 : 0,
            "isHigh": isHigh ? 1 : 0,
            "isNormal": isNormal ? 1 : 0,
          });

          //print("${m.toString()} $rmse $trainingDataRMSE");
        }

        //
      }
    }
  }

  //Map<String, List<List<double>>> bestTrainingSet = {};
  Map<String, List<double>> bestFuture = {};

  rmesess.forEach((readings, readingsValue) {
    readingsValue.forEach((testReadings, testReadingsValue) {
      testReadingsValue.forEach((model, l) {
        // calculate the average RMSE for each model
        List<double> totalTRMSE = [];
        List<double> totalRMSE = [];
        int totalSelected = 0;
        int totalLowest = 0;
        int totalAlarmTP = 0;
        int totalAlarmFP = 0;
        int totalAlarmFN = 0;
        int totalAlarmTN = 0;

        int totalSnoozeLowTP = 0;
        int totalSnoozeLowFP = 0;
        int totalSnoozeLowFN = 0;
        int totalSnoozeLowTN = 0;

        int totalSnoozeHighTP = 0;
        int totalSnoozeHighFP = 0;
        int totalSnoozeHighFN = 0;
        int totalSnoozeHighTN = 0;

        int totalLow = 0;
        int totalHigh = 0;
        int totalNormal = 0;

        var n = 0;
        for (var lv in l) {
          if (lv['rmse'] == null || lv['trmse'] == null) {
            continue;
          }

          double rmse = lv['rmse']!;
          double trmse = lv['trmse']!;

          totalSelected += lv['selected']!.toInt();
          totalLowest += lv['lowest']!.toInt();

          totalAlarmTP += lv['predictAlarmTP']!.toInt();
          totalAlarmFP += lv['predictAlarmFP']!.toInt();
          totalAlarmFN += lv['predictAlarmFN']!.toInt();
          totalAlarmTN += lv['predictAlarmTN']!.toInt();

          totalSnoozeLowTP += lv['predictSnoozeLowTP']!.toInt();
          totalSnoozeLowFP += lv['predictSnoozeLowFP']!.toInt();
          totalSnoozeLowFN += lv['predictSnoozeLowFN']!.toInt();
          totalSnoozeLowTN += lv['predictSnoozeLowTN']!.toInt();

          totalSnoozeHighTP += lv['predictSnoozeHighTP']!.toInt();
          totalSnoozeHighFP += lv['predictSnoozeHighFP']!.toInt();
          totalSnoozeHighFN += lv['predictSnoozeHighFN']!.toInt();
          totalSnoozeHighTN += lv['predictSnoozeHighTN']!.toInt();

          totalLow += lv['isLow']!.toInt();
          totalHigh += lv['isHigh']!.toInt();
          totalNormal += lv['isNormal']!.toInt();

          if (rmse.isNaN ||
              trmse.isNaN ||
              rmse.isInfinite ||
              trmse.isInfinite) {
            continue;
          }

          totalTRMSE.add(trmse);
          totalRMSE.add(rmse);

          n++;
        }
        var totalAlarmN = totalAlarmTN + totalAlarmFN;
        var totalAlarmP = totalAlarmFP + totalAlarmTP;
        var totalAlarm = totalAlarmN + totalAlarmP;

        var totalSnoozeLowN = totalSnoozeLowTN + totalSnoozeLowFN;
        var totalSnoozeLowP = totalSnoozeLowFP + totalSnoozeLowTP;
        var totalSnoozeLow = totalSnoozeLowN + totalSnoozeLowP;

        var totalSnoozeHighN = totalSnoozeHighTN + totalSnoozeHighFN;
        var totalSnoozeHighP = totalSnoozeHighFP + totalSnoozeHighTP;
        var totalSnoozeHigh = totalSnoozeHighN + totalSnoozeHighP;

        // print(
        //     "$totalAlarmFN $totalAlarmTN $totalAlarmFP $totalAlarmTP $totalAlarmP $totalAlarmN $totalAlarm");
        // print(
        //     "$totalSnoozeLowFN $totalSnoozeLowTN $totalSnoozeLowFP $totalSnoozeLowTP");
        // print(
        //     "$totalSnoozeHighFN $totalSnoozeHighTN $totalSnoozeHighFP $totalSnoozeHighTP");

        var rmse = median(totalRMSE);
        var trmse = median(totalTRMSE);

        var modelName = model.replaceFirst("Regression", "");

        var modelNameFR = "$modelName($readings)";

        // bestTrainingSet[modelName] ??= [[], [], [], [], [], []];
        // bestTrainingSet[modelName]![readings - 2].add(rmse);

        bestFuture[modelNameFR] ??= List.filled(12, 0);
        bestFuture[modelNameFR]![testReadings - 1] = rmse;

        var accuracyAlarmCorrect =
            ((totalAlarmTN + totalAlarmTP) * 100.0) / totalAlarm;

        var accuracySnoozeLowCorrect =
            ((totalSnoozeLowTN + totalSnoozeLowTP) * 100.0) / totalSnoozeLow;

        var accuracySnoozeHighCorrect =
            ((totalSnoozeHighTN + totalSnoozeHighTP) * 100.0) / totalSnoozeHigh;

        var annoyingAlarms = (totalAlarmFP * 100.0) / totalAlarmP;
        var missedAlarms = (totalAlarmFN * 100.0) / totalAlarmN;
        var dangerousLowSnoozes = (totalSnoozeLowFP * 100.0) / totalSnoozeLowP;
        var missedLowSnoozes = (totalSnoozeLowFN * 100.0) / totalSnoozeLowN;
        var dangerousHighSnoozes =
            (totalSnoozeHighFP * 100.0) / totalSnoozeHighP;
        var missedHighSnoozes = (totalSnoozeHighFN * 100.0) / totalSnoozeHighN;

        //print(
        //    "$model,$readings,$testReadings,$n,${dp4(trmse)},${dp4(rmse)},$totalSelected,$totalLowest, ${dp4(accuracyAlarmCorrect)}, ${dp4(accuracySnoozeCorrect)}, ${dp4(annoyingAlarms)}, ${dp4(dangerousSnoozes)}");

        print(
            "$model,$testReadings, alarm, ${dp4(accuracyAlarmCorrect)}, $totalAlarmFP , $totalAlarmTP, ${dp4(annoyingAlarms)}, ${dp4(missedAlarms)}");

        print(
            "$model,$testReadings, slow, ${dp4(accuracySnoozeLowCorrect)}, $totalSnoozeLowFP, $totalSnoozeLowTP, ${dp4(dangerousLowSnoozes)},  ${dp4(missedLowSnoozes)},}");

        print(
            "$model,$testReadings, shigh,  ${dp4(accuracySnoozeHighCorrect)}, $totalSnoozeHighFP,  $totalSnoozeHighTP, ${dp4(dangerousHighSnoozes)}, ${dp4(missedHighSnoozes)}");
      });
    });
  });
  //print(rmesess);
  // print("");
  // print("");
  // var keys = bestTrainingSet.keys.toList()..sort();
  // for (var m in keys) {
  //   var ds = bestTrainingSet[m]!;
  //   print("$m,${ds.map((e) => median(e)).join(",")}");
  // }

  print("");
  print("");

  var keys = bestFuture.keys.toList()..sort();
  for (var m in keys) {
    var ds = bestFuture[m]!;
    print("$m,${ds.map(dp4).join(",")}");
  }
  return true;
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

double dp4(num value) {
  if (value.isNaN || value.isInfinite) {
    return value.toDouble();
  }
  return (value * 1000.0).round() / 1000.0;
}

double median(List<double> nums) {
  nums.sort();
  if (nums.length.isOdd) {
    return dp4(nums[nums.length ~/ 2]);
  }
  return dp4((nums[nums.length ~/ 2] + nums[nums.length ~/ 2 - 1]) / 2.0);
}

// When Would predictive Alarm
// Will Alarm, Should Alarm
(bool, bool) predictiveAlarm(
    bool isLow,
    isHigh,
    isNormal,
    isGoingToBeLow,
    isGoingToBeHigh,
    isGoingToBeNormal,
    predictedLow,
    predictedHigh,
    predictedNormal) {
  // It would already be alarming if low or high
  if (!isNormal) {
    return (false, false);
  }

  var predictedAalrm = false;
  var shouldAlarm = false;
  if (predictedLow) {
    predictedAalrm = true;
  }

  if (isGoingToBeLow) {
    shouldAlarm = true;
  }

  return (predictedAalrm, shouldAlarm);
}

(bool, bool) smartSnoozeLow(
    bool isLow,
    isHigh,
    isNormal,
    isGoingToBeLow,
    isGoingToBeHigh,
    isGoingToBeNormal,
    predictedLow,
    predictedHigh,
    predictedNormal) {
  // It will only be alarming if it is already low or high
  if (isNormal) {
    return (false, false);
  }

  var predictSnooze = false;
  var shouldSnooze = false;

  if ((isLow) && predictedNormal) {
    predictSnooze = true;
  }

  if ((isLow) && isGoingToBeNormal) {
    shouldSnooze = true;
  }

  return (predictSnooze, shouldSnooze);
}

(bool, bool) smartSnoozeHigh(
    bool isLow,
    isHigh,
    isNormal,
    isGoingToBeLow,
    isGoingToBeHigh,
    isGoingToBeNormal,
    predictedLow,
    predictedHigh,
    predictedNormal) {
  // It will only be alarming if it is already low or high
  if (isNormal) {
    return (false, false);
  }

  var predictSnooze = false;
  var shouldSnooze = false;

  if ((isHigh) && predictedNormal) {
    predictSnooze = true;
  }

  if ((isHigh) && isGoingToBeNormal) {
    shouldSnooze = true;
  }

  return (predictSnooze, shouldSnooze);
}
