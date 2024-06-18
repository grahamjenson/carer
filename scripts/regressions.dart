import 'dart:convert';
import 'dart:io';

import "implregressions.dart";

final double minsToMinus = DateTime(2024, 06, 13)
        .subtract(const Duration(days: 100))
        .millisecondsSinceEpoch /
    60000.0;

double fnX(num x) {
  var ret = ((x / 60000.0).round().toDouble() - minsToMinus).round().toDouble();

  return ret;
}

int fnRX(double x) => (x * 60000.0).toInt() + minsToMinus.toInt();

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

  // Variables
  // training readings
  // check real values

  printTest(times, sgvs);
}

bool printTest(List<double> times, List<double> sgvs) {
  Map<int, Map<int, Map<String, List<Map<String, double>>>>> rmesess = {};

  // Number of tests
  // When low and linear predicts going up, does it go up and just miss?
  // When high and linear predicts going down, does it go down and just miss?
  // Using this system and understanding the error variance what are the safe guarged we should place
  // four days
  var numOfTests = 12 * 24 * 80;
  var jump = 1;

  print("Number of Runs: ${numOfTests / jump}");

  for (var start = 10; start < numOfTests * jump; start += jump) {
    for (var readings = 2; readings < 8; readings++) {
      var end = start + readings;
      var trainingTimes = times.sublist(start, end).toList();
      var trainingSgvs = sgvs.sublist(start, end).toList();
      var minTime = ((trainingTimes)..sort()).first - 20;

      for (var testReadings = 1; testReadings <= 6; testReadings++) {
        var testingTimes =
            times.sublist(end + testReadings - 1, end + testReadings).toList();
        var testingSgvs =
            sgvs.sublist(end + testReadings - 1, end + testReadings).toList();

        // Big numbers cause overflows in flutter, need to reduce mins ago time

        var nrmtrainingTimes = trainingTimes.map((e) => e - minTime).toList();
        var nrmtestingTimes = testingTimes.map((e) => e - minTime).toList();

        // We are only testing the value at the position, not the average value (we can do that later)
        assert(testingSgvs.length == 1);

        // print(testingSgvs);
        var testSVG = testingSgvs.first;

        var b = BestMatchRegression(
            nrmtrainingTimes.reversed.toList(), trainingSgvs.reversed.toList());

        double minErrorVariance = double.infinity;
        for (var m in b.models) {
          if (readings == 2 && m is QuadraticRegression) {
            continue;
          }
          var modelName = m.runtimeType.toString();

          var (trainingDataRMSE, _) =
              m.rootMeanSquaredError(nrmtrainingTimes, trainingSgvs);

          var (rmse, preds) =
              m.rootMeanSquaredError(nrmtestingTimes, testingSgvs);

          rmesess[readings] ??= {};
          rmesess[readings]![testReadings] ??= {};
          rmesess[readings]![testReadings]![modelName] ??= [];

          // Calculate the ranges
          var isLow = trainingSgvs.last < 72;
          var isHigh = trainingSgvs.last > 180;
          var isNormal = !isLow && !isHigh;
          var isGoingToBeLow = testSVG < 72;
          var isGoingToBeHigh = testSVG > 180;
          var isGoingToBeNormal = !isGoingToBeLow && !isGoingToBeHigh;

          var predictedLow = preds.last < 72;
          var predictedHigh = preds.last > 180;
          var predictedNormal = !predictedLow && !predictedHigh;

          // simple implementations of smart snooze and predictive low
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

          rmesess[readings]![testReadings]![modelName]!.add({
            'trmse': trainingDataRMSE,
            'rmse': rmse,
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

  Map<String, Map<String, List<double>>> orth = {
    "rmse": {},
    "trmse": {},
    "predictAlarmTPRatioList": {},
    "predictAlarmFPRatioList": {},
    "predictAlarmFPList": {},
    "predictAlarmTPList": {},
    "smartLowTPRatioList": {},
    "smartLowFPRatioList": {},
    "smartLowFPList": {},
    "smartLowTPList": {},
    "predictAlarmFNList": {},
    "predictAlarmTNList": {},
    "smartLowFNList": {},
    "smartLowTNList": {},
  };

  rmesess.forEach((readings, readingsValue) {
    readingsValue.forEach((futureReading, futureReadingValue) {
      futureReadingValue.forEach((model, l) {
        var modelName = model.replaceFirst("Regression", "");
        var modelNameFR = "$modelName($readings)";

        // vs readings
        orth["rmse"]![modelNameFR] ??= [];
        orth["trmse"]![modelNameFR] ??= [];
        orth["predictAlarmTPRatioList"]![modelNameFR] ??= [];
        orth["predictAlarmFPRatioList"]![modelNameFR] ??= [];
        orth["predictAlarmFPList"]![modelNameFR] ??= [];
        orth["predictAlarmTPList"]![modelNameFR] ??= [];
        orth["predictAlarmFNList"]![modelNameFR] ??= [];
        orth["predictAlarmTNList"]![modelNameFR] ??= [];

        orth["smartLowTPRatioList"]![modelNameFR] ??= [];
        orth["smartLowFPRatioList"]![modelNameFR] ??= [];
        orth["smartLowFPList"]![modelNameFR] ??= [];
        orth["smartLowTPList"]![modelNameFR] ??= [];
        orth["smartLowFNList"]![modelNameFR] ??= [];
        orth["smartLowTNList"]![modelNameFR] ??= [];

        var rmseList = orth["rmse"]![modelNameFR]!;
        var trmseList = orth["trmse"]![modelNameFR]!;

        var predictAlarmTPRatioList =
            orth["predictAlarmTPRatioList"]![modelNameFR]!;
        var predictAlarmFPRatioList =
            orth["predictAlarmFPRatioList"]![modelNameFR]!;
        var predictAlarmFPList = orth["predictAlarmFPList"]![modelNameFR]!;
        var predictAlarmTPList = orth["predictAlarmTPList"]![modelNameFR]!;

        var smartLowTPRatioList = orth["smartLowTPRatioList"]![modelNameFR]!;
        var smartLowFPRatioList = orth["smartLowFPRatioList"]![modelNameFR]!;
        var smartLowFPList = orth["smartLowFPList"]![modelNameFR]!;
        var smartLowTPList = orth["smartLowTPList"]![modelNameFR]!;

        var predictAlarmFNList = orth["predictAlarmFNList"]![modelNameFR]!;
        var predictAlarmTNList = orth["predictAlarmTNList"]![modelNameFR]!;
        var smartLowFNList = orth["smartLowFNList"]![modelNameFR]!;
        var smartLowTNList = orth["smartLowTNList"]![modelNameFR]!;

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

        var accuracyAlarmCorrect =
            ((totalAlarmTN + totalAlarmTP) * 100.0) / totalAlarm;

        var accuracySnoozeLowCorrect =
            ((totalSnoozeLowTN + totalSnoozeLowTP) * 100.0) / totalSnoozeLow;

        var accuracySnoozeHighCorrect =
            ((totalSnoozeHighTN + totalSnoozeHighTP) * 100.0) / totalSnoozeHigh;

        var alarmFPRatio = (totalAlarmFP * 100.0) / totalAlarmP;
        var alarmTPRatio = (totalAlarmTP * 100.0) / totalAlarmP;
        var missedAlarms = (totalAlarmFN * 100.0) / totalAlarmN;

        var snoozeFPRatio = (totalSnoozeLowFP * 100.0) / totalSnoozeLowP;
        var snoozeTPRatio = (totalSnoozeLowTP * 100.0) / totalSnoozeLowP;
        var missedLowSnoozes = (totalSnoozeLowFN * 100.0) / totalSnoozeLowN;
        var dangerousHighSnoozes =
            (totalSnoozeHighFP * 100.0) / totalSnoozeHighP;
        var missedHighSnoozes = (totalSnoozeHighFN * 100.0) / totalSnoozeHighN;

        var rmse = median(totalRMSE);

        rmseList.add(rmse);
        trmseList.addAll(totalTRMSE);

        predictAlarmTPRatioList.add(alarmTPRatio);
        predictAlarmFPRatioList.add(alarmFPRatio);
        predictAlarmFPList.add(totalAlarmFP.toDouble());
        predictAlarmTPList.add(totalAlarmTP.toDouble());
        predictAlarmFNList.add(totalAlarmFN.toDouble());
        predictAlarmTNList.add(totalAlarmTN.toDouble());

        smartLowTPRatioList.add(snoozeTPRatio);
        smartLowFPRatioList.add(snoozeFPRatio);
        smartLowFPList.add(totalSnoozeLowFP.toDouble());
        smartLowTPList.add(totalSnoozeLowTP.toDouble());
        smartLowFNList.add(totalSnoozeLowFN.toDouble());
        smartLowTNList.add(totalSnoozeLowTN.toDouble());

        //print(
        //    "$model,$readings,$futureReading,$n,${dp4(trmse)},${dp4(rmse)},$totalSelected,$totalLowest, ${dp4(accuracyAlarmCorrect)}, ${dp4(accuracySnoozeCorrect)}, ${dp4(annoyingAlarms)}, ${dp4(dangerousSnoozes)}");

        // print(
        //     "$model,$futureReading, alarm, ${dp4(accuracyAlarmCorrect)}, $totalAlarmFP , $totalAlarmTP, ${dp4(annoyingAlarms)}, ${dp4(missedAlarms)}");

        // print(
        //     "$model,$futureReading, slow, ${dp4(accuracySnoozeLowCorrect)}, $totalSnoozeLowFP, $totalSnoozeLowTP, ${dp4(dangerousLowSnoozes)},  ${dp4(missedLowSnoozes)},}");

        // print(
        //     "$model,$futureReading, shigh,  ${dp4(accuracySnoozeHighCorrect)}, $totalSnoozeHighFP,  $totalSnoozeHighTP, ${dp4(dangerousHighSnoozes)}, ${dp4(missedHighSnoozes)}");
      });
    });
  });

  // fix trmse
  Map<String, List<double>> newM = {};
  for (var mm in orth["trmse"]!.keys.toList()) {
    var nums = orth["trmse"]![mm]!;
    var newModelName = mm.substring(0, mm.length - 3);
    newM[newModelName] ??= [];
    newM[newModelName]!.add(median(nums));
  }
  orth["trmse"] = newM;
  for (var chart in (orth.keys.toList()..sort()).toList()) {
    print("");
    print("");
    print("$chart,1,2,3,4,5,6");
    for (var model in (orth[chart]!.keys.toList()..sort()).toList()) {
      var values = orth[chart]![model]!;
      print("$model,${values.join(",")}");
    }
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

void prettyPrintMap(Map map) {
  var prettyString = const JsonEncoder.withIndent('  ').convert(map);
  print(prettyString);
}
