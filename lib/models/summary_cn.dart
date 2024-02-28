import 'dart:async';
import 'dart:developer';

import 'package:carer/models/settings/debug_settings.dart';
import 'package:carer/models/settings_cn.dart';
import 'package:carer/nsclient/nsclient.dart';
import 'package:carer/nsclient/summary.dart';
import 'package:flutter/material.dart';

class SummaryCN extends ChangeNotifier {
  Settings settings;

  // When this updates lots of things will change
  Summary summary = Summary.empty;
  bool _summaryToBeUpdated = true;
  String _updateReason = "";

  SummaryCN({required this.settings}) {
    Timer.periodic(const Duration(seconds: 1), (Timer t) => update());
    update();
    settings.addListener(() {
      _summaryToBeUpdated = true;
      _updateReason = "Added Listener";
    });
  }

  update() {
    if (summary.ageInSeconds() > 15) {
      _summaryToBeUpdated = true;
      _updateReason = "Age older than 15";
    }

    if (summary.lastSGV != null) {
      var sgvage = summary.lastSGV!.age.inSeconds;
      // Check more frequently when the SGV is about to expire
      if (sgvage > 295 && sgvage < 315) {
        _summaryToBeUpdated = true;
        _updateReason = "Last SGV older than 290";
      }
    }

    if (_summaryToBeUpdated) {
      // clenaup

      // Calling update
      if (settings.debugSettings.debug &&
          settings.debugSettings.debugSummary != DebugSummary.off) {
        log("USING DEBUG SUMMARY: $_updateReason");
        _updateReason = "";
        _summaryToBeUpdated = false;
        useDebugSummary();
      } else {
        log("UPDATING SUMMARY: $_updateReason");
        _updateReason = "";
        _summaryToBeUpdated = false;
        updateSummary();
      }
    }
  }

  updateSummary() {
    var (nsURL, nsToken) = settings.nightscoutURLAndToken;
    NSClient().getSummary(nsURL, nsToken).catchError((e) {
      log("GETTING SUMMARY ERROR: $e");
      _summaryToBeUpdated = true;
      return Summary.empty;
    }).then((value) {
      summary = value;
      notifyListeners();
    });
  }

  useDebugSummary() {
    summary = settings.debugSettings.debugSummary.summary(settings);
    notifyListeners();
  }
}
