import 'dart:convert';
import 'dart:io';

import "implregressions.dart";

void main() async {
  // data.json is a tide pool dump of JSON data
  var entries = await parseJsonFromFile("data.json");

  //sort by first element
  entries.sort((a, b) => b.$1.compareTo(a.$1));
  entries = entries.map((e) => (e.$1, e.$2.round().toDouble())).toList();

  print(entries.length);

  final double mimnutesFromEpochToLastWeek = DateTime.now()
          .subtract(const Duration(days: 100))
          .millisecondsSinceEpoch /
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
    -18: {},
    0: {},
    18: {},
  };

  // Number of tests
  // When low and linear predicts going up, does it go up and just miss?
  // When high and linear predicts going down, does it go down and just miss?
  // Using this system and understanding the error variance what are the safe guarged we should place
  // four days
  var numOfTests = 12 * 24 * 14;
  var readings = 5;
  for (var lowHighDiff in [(-18, 18), (0, 0), (18, -18)]) {
    var (lowDiff, highDiff) = lowHighDiff;

    rmesess[lowDiff] ??= {};
    // Jump further by 5 each time
    for (var start = 0; start < numOfTests * 6; start += 6) {
      var end = start + readings;
      var trainingTimes = times.sublist(start, end).toList();
      var trainingSgvs = sgvs.sublist(start, end).toList();
      //print("TRAIN $trainingTimes $trainingSgvs");

      for (var testReadings = 1; testReadings <= 12; testReadings++) {
        var testingTimes =
            times.sublist(end + testReadings - 1, end + testReadings).toList();
        var testingSgvs =
            sgvs.sublist(end + testReadings - 1, end + testReadings).toList();

        assert(testingSgvs.length == 1);
        var testSVG = testingSgvs.first;

        //print("TEST $testingTimes $testingSgvs");
        var b = BestMatchRegression(
            trainingTimes.reversed.toList(), trainingSgvs.reversed.toList());

        rmesess[lowDiff]![testReadings] ??= {};

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

          var predictAlarmGood = predictAlarm && willAlarm;
          var predictAlarmFP = predictAlarm && !willAlarm;
          var predictAlarmFN = !predictAlarm && willAlarm;

          var predictSnoozeLowGood = predictSnoozeLow && willSnoozeLow;
          var predictSnoozeLowFP = predictSnoozeLow && !willSnoozeLow;
          var predictSnoozeLowFN = !predictSnoozeLow && willSnoozeLow;
          var predictSnoozeHighGood = predictSnoozeHigh && willSnoozeHigh;
          var predictSnoozeHighFP = predictSnoozeHigh && !willSnoozeHigh;
          var predictSnoozeHighFN = !predictSnoozeHigh && willSnoozeHigh;

          rmesess[lowDiff]![testReadings]![modelName]!.add({
            'trmse': trainingDataRMSE,
            'rmse': rmse,
            "selected": b.selected == m ? 1 : 0,
            "lowest": 0,
            "predictAlarmGood": predictAlarmGood ? 1 : 0,
            "predictAlarmFP": predictAlarmFP ? 1 : 0,
            "predictAlarmFN": predictAlarmFN ? 1 : 0,
            "predictSnoozeLowGood": predictSnoozeLowGood ? 1 : 0,
            "predictSnoozeLowFP": predictSnoozeLowFP ? 1 : 0,
            "predictSnoozeLowFN": predictSnoozeLowFN ? 1 : 0,
            "predictSnoozeHighGood": predictSnoozeHighGood ? 1 : 0,
            "predictSnoozeHighFP": predictSnoozeHighFP ? 1 : 0,
            "predictSnoozeHighFN": predictSnoozeHighFN ? 1 : 0,
          });

          //print("${m.toString()} $rmse $trainingDataRMSE");
        }
        rmesess[lowDiff]![testReadings]![
                shouldHaveBeenSelected.runtimeType.toString()]!
            .last['lowest'] = 1.0;
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
        int totalpredictAlarmGood = 0;
        int totalpredictAlarmFP = 0;
        int totalpredictAlarmFN = 0;
        int totalpredictSnoozeLowGood = 0;
        int totalpredictSnoozeLowFP = 0;
        int totalpredictSnoozeLowFN = 0;

        int totalpredictSnoozeHighGood = 0;
        int totalpredictSnoozeHighFP = 0;
        int totalpredictSnoozeHighFN = 0;

        var n = 0;
        for (var lv in l) {
          if (lv['rmse'] == null || lv['trmse'] == null) {
            continue;
          }

          double rmse = lv['rmse']!;
          double trmse = lv['trmse']!;

          totalSelected += lv['selected']!.toInt();
          totalLowest += lv['lowest']!.toInt();
          totalpredictAlarmGood += lv['predictAlarmGood']!.toInt();
          totalpredictAlarmFP += lv['predictAlarmFP']!.toInt();
          totalpredictAlarmFN += lv['predictAlarmFN']!.toInt();

          totalpredictSnoozeLowGood += lv['predictSnoozeLowGood']!.toInt();
          totalpredictSnoozeLowFP += lv['predictSnoozeLowFP']!.toInt();
          totalpredictSnoozeLowFN += lv['predictSnoozeLowFN']!.toInt();

          totalpredictSnoozeHighGood += lv['predictSnoozeHighGood']!.toInt();
          totalpredictSnoozeHighFP += lv['predictSnoozeHighFP']!.toInt();
          totalpredictSnoozeHighFN += lv['predictSnoozeHighFN']!.toInt();

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

        var rmse = median(totalRMSE);
        var trmse = median(totalTRMSE);

        var modelName = model.replaceFirst("Regression", "");

        var modelNameFR = "$modelName($readings)";

        // bestTrainingSet[modelName] ??= [[], [], [], [], [], []];
        // bestTrainingSet[modelName]![readings - 2].add(rmse);

        bestFuture[modelNameFR] ??= List.filled(12, 0);
        bestFuture[modelNameFR]![testReadings - 1] = rmse;

        var fractionAlarmCorrect =
            ((n - totalpredictAlarmFP - totalpredictAlarmFN) * 100.0) / n;
        var fractionSnoozeLowCorrect =
            ((n - totalpredictSnoozeLowFP - totalpredictSnoozeLowFN) * 100.0) /
                n;

        var fractionSnoozeHighCorrect =
            ((n - totalpredictSnoozeHighFP - totalpredictSnoozeHighFN) *
                    100.0) /
                n;

        var annoyingAlarms = (totalpredictAlarmFP * 100.0) / n;
        var missedAlarms = (totalpredictAlarmFN * 100.0) / n;
        var dangerousLowSnoozes = (totalpredictSnoozeLowFP * 100.0) / n;
        var missedLowSnoozes = (totalpredictSnoozeLowFN * 100.0) / n;
        var dangerousHighSnoozes = (totalpredictSnoozeHighFP * 100.0) / n;
        var missedHighSnoozes = (totalpredictSnoozeHighFN * 100.0) / n;

        //print(
        //    "$model,$readings,$testReadings,$n,${dp4(trmse)},${dp4(rmse)},$totalSelected,$totalLowest, ${dp4(fractionAlarmCorrect)}, ${dp4(fractionSnoozeCorrect)}, ${dp4(annoyingAlarms)}, ${dp4(dangerousSnoozes)}");
        print(
            "$model,$readings,$testReadings, $n, ${dp4(fractionAlarmCorrect)}, ${dp4(annoyingAlarms)}, ${dp4(missedAlarms)}, ${dp4(fractionSnoozeLowCorrect)}, ${dp4(dangerousLowSnoozes)},  ${dp4(missedLowSnoozes)}, ${dp4(fractionSnoozeHighCorrect)}, ${dp4(dangerousHighSnoozes)}, ${dp4(missedHighSnoozes)}");
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
