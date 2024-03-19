// this class is a provider describing the state of the person with type 1 diabetes
// e.g. if they are high, dropping fast, predicstions...
// this is meant to seperate the logic from the UI and alarms

import 'dart:async';

import 'package:carer/models/settings_cn.dart';
import 'package:carer/models/summary_cn.dart';
import 'package:carer/nsclient/summary.dart';
import 'package:carer/utils/math.dart';
import 'package:flutter/material.dart';

class T1DCN extends ChangeNotifier {
  Settings settings;
  SummaryCN summaryCn;
  Summary get summary => summaryCn.summary;

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

  T1DCN({required this.settings, required this.summaryCn}) {
    // Every 60 seconds check if the summary is too old or has errors
    Timer.periodic(
        const Duration(seconds: 60), (Timer t) => summaryAgeMissedDataError());

    summaryCn.addListener(() {
      checkSummary();
    });
  }

  void summaryAgeMissedDataError() {
    summaryAgeInMinutes = summary.ageInSeconds() / 60;
    if (summaryAgeInMinutes > 5.5) {
      oldSummary = true;
    } else {
      oldSummary = false;
    }
    notifyListeners();
  }

  List<Range5> targetRange5ForMins(int minutes) {
    return summary.sgvsLastMins(minutes).map((e) {
      var (t, _) = targetRange(settings, e.sgv);
      return t;
    }).toList();
  }

  void checkSummary() {
    var lastSGV = summary.lastSGV;
    if (lastSGV == null) {
      return;
    }

    // Calculating Target Range
    var (tr, trp) = targetRange(settings, lastSGV.sgv);
    targetRange5 = tr;
    targetRange5Proportion = trp;

    // Calculating Diff Range
    var (dr, drp) = diffRange(lastSGV.sgv, lastSGV.diffPer5Mins);
    diffRange7 = dr;
    diffRange7Proportion = drp;

    notifyListeners();
  }

  //// Munging

  List<int> diffPer5Minute(int minutes) {
    List<int> diffs = [];
    var sgvs = summary.sgvsLastMins(minutes);

    for (var sgv in sgvs) {
      diffs.add(sgv.diffPer5Mins);
    }

    return diffs;
  }
}
