// this class is a provider describing the state of the person with type 1 diabetes
// e.g. if they are high, dropping fast, predicstions...
// this is meant to seperate the logic from the UI and alarms

import 'dart:async';

import 'package:carer/models/sgv.dart';
import 'package:carer/signals/settings/alarm_settings.dart';
import 'package:carer/utils/math.dart';
import 'package:signals/signals_flutter.dart';

class T1DSettings {
  // Target information
  Range5 targetRange5 = Range5.mid;
  double targetRange5Proportion = 0.0;
  final List<Range5> targetRangesPerMinute = [];

  // Diff information
  Range7 diffRange7 = Range7.mid;
  double diffRange7Proportion = 0.0;

  // Age information
  bool oldSummary = false;
  double summaryAgeInMinutes = 0;

  T1DSettings() {
    // Every 60 seconds check if the summary is too old or has errors
    Timer.periodic(
        const Duration(seconds: 60), (Timer t) => summaryAgeMissedDataError());
  }

  void summaryAgeMissedDataError() {
    var lastSGV = SGV.lastSGV.value.value;
    if (lastSGV == null) {
      return;
    }
    summaryAgeInMinutes = lastSGV.age.inSeconds / 60;
    if (summaryAgeInMinutes > 5.5) {
      oldSummary = true;
    } else {
      oldSummary = false;
    }
  }

  List<Range5> targetRange5ForMins(int minsAgo) {
    var sgvs = SGV.last3Hours().value!.where((e) => e.minsAgo < minsAgo);
    return sgvs.map((e) {
      var (t, _) = targetRange(e.value);
      return t;
    }).toList();
  }

  void checkSummary() {
    effect(() {
      try {
        var lastSGV = SGV.lastSGV.value.value;
        if (lastSGV == null) {
          return;
        }
        // Calculating Target Range
        var (tr, trp) = targetRange(lastSGV.value);
        targetRange5 = tr;
        targetRange5Proportion = trp;

        // Calculating Diff Range
        var (dr, drp) = diffRange(AlarmSettings().fastDropDelta,
            AlarmSettings().fastRiseDelta, lastSGV.rate5m ?? 0);

        diffRange7 = dr;
        diffRange7Proportion = drp;
      } catch (e) {
        print("Error in checkSummary: $e");
      }
    });
  }

  //// Mungingx

  List<int> diffPer5Minute(int minsAgo) {
    var sgvs = SGV.last3Hours().value!.where((e) => e.minsAgo < minsAgo);

    List<int> diffs = [];
    for (var sgv in sgvs) {
      diffs.add(sgv.rate5m ?? 0);
    }

    return diffs;
  }
}
