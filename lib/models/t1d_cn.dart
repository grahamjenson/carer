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
    var delta = summary.delta;
    if (lastSGV == null || delta == null) {
      return;
    }

    // Calculating Target Range
    var (tr, trp) = targetRange(settings, lastSGV.sgv);
    targetRange5 = tr;
    targetRange5Proportion = trp;

    // Calculating Diff Range
    var (dr, drp) = diffRange(lastSGV.sgv, delta.sgv);
    diffRange7 = dr;
    diffRange7Proportion = drp;

    notifyListeners();
  }

  //// Munging

  // TODO test
  List<SGV> cleanedSGVs(int minutes) {
    var sgvs = summary.sgvsLastMins(minutes);

    Duration minTimeDiff = const Duration(minutes: 1);

    // There are a bunch of ways that there could be multiple SGVS witing a minute.
    // e.g. when there ia a calibration, or a new sensor giving a close new reading
    // This may lead to very strange results, like diffs nearing infinity
    // So we remove that possibility by removing any SGVs that are within a minute of each other
    List<SGV> cleanedSgvs = [];

    for (int i = 1; i < sgvs.length; i++) {
      var tbefore = sgvs[i - 1].mills;
      var tafter = sgvs[i].mills;

      if (tafter.difference(tbefore) >= minTimeDiff) {
        cleanedSgvs.add(sgvs[i - 1]);
      }
    }
    cleanedSgvs.add(sgvs.last);

    return cleanedSgvs;
  }

  // TODO test
  List<int> diffPer5Minute(int minutes) {
    List<int> diffs = [];
    // we assume that there is a linear difference between all the sgvs
    var sgvs = cleanedSGVs(minutes);
    for (int i = 0; i < sgvs.length - 1; i++) {
      var first = sgvs[i];
      var second = sgvs[i + 1];
      var diff = first.sgv - second.sgv;
      // This fun bit of code is meant to be here if there is no information available for a reading or two
      var mins5 =
          ((second.mills.difference(first.mills).inSeconds / 60) / 5).round();
      var diffPerMin = (diff / mins5);
      diffs.addAll(List.filled(mins5, diffPerMin.toInt()));
    }

    return diffs;
  }
}
