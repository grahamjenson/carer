import 'dart:async';
import 'dart:developer';

import 'package:carer/change_notifiers/settings_cn.dart';
import 'package:carer/models/bolus.dart';
import 'package:carer/models/carbs.dart';
import 'package:carer/models/profile.dart';
import 'package:carer/models/sgv.dart';
import 'package:carer/models/tempbasal.dart';
import 'package:carer/models/temptarget.dart';
import 'package:carer/nsclient/nsclient.dart';
import 'package:carer/nsclient/summary.dart';
import 'package:flutter/material.dart';

class UpdateCN extends ChangeNotifier {
  SettingsCN settings;

  // When this updates lots of things will change
  Summary summary = Summary.empty;
  bool _summaryToBeUpdated = true;
  String _updateReason = "";

  UpdateCN({required this.settings}) {
    Timer.periodic(const Duration(seconds: 1), (Timer t) => update());
    update();

    // If settings update grab latest summary
    settings.addListener(() {
      _summaryToBeUpdated = true;
      _updateReason = "Added Listener";
    });
  }

  update() {
    checkUpdateSummary();

    if (_summaryToBeUpdated) {
      log("UPDATING SUMMARY: $_updateReason");
      _updateReason = "";
      _summaryToBeUpdated = false;
      updateSummary();
    }
  }

  checkUpdateSummary() async {
    if (summary.ageInSeconds() > 15) {
      _summaryToBeUpdated = true;
      _updateReason = "Age older than 15";
    }
    var lastSGV = await SGV.lastSGV();
    if (lastSGV != null) {
      var sgvage = lastSGV.age.inSeconds;

      // Check more frequently when the SGV is about to expire
      if (sgvage > 305 && sgvage < 320) {
        _summaryToBeUpdated = true;
        _updateReason = "Last SGV older than 300";
      }
    }
  }

  updateSummary() async {
    var (nsURL, nsToken) = settings.nightscoutURLAndToken;
    NSClient().getSummary(nsURL, nsToken).catchError((e) {
      log("GETTING SUMMARY ERROR: $e, $nsURL");
      _summaryToBeUpdated = true;
      return Summary.empty;
    }).then((value) async {
      // Assign the raw summary value
      summary = value;

      // convert the summary to models
      List<SGV> sgvs = [];
      for (var sgv in summary.sgvs.sgvs) {
        sgvs.add(SGV(value: sgv.sgv, date: sgv.mills));
      }
      var saveAll = sgvs.map((e) => e.save()).toList();
      int sgvUpdates = (await Future.wait(saveAll)).where((b) => b).length;

      List<Bolus> boluses = [];
      for (var bolus in summary.treatments.boluses()) {
        boluses.add(Bolus(value: bolus.insulin!, date: bolus.mills));
      }
      var bolusUpdates = await Bolus.createOrUpdate(boluses);

      List<Carbs> carbs = [];
      for (var carb in summary.treatments.carbs()) {
        carbs.add(Carbs(value: carb.carbs!.round(), date: carb.mills));
      }
      var carbUpdates = await Carbs.createOrUpdate(carbs);

      List<TempBasal> tempBasals = [];
      for (var tempBasal in summary.tempBasals.tempBasals) {
        tempBasals.add(TempBasal(
            startDate: tempBasal.date,
            duration: tempBasal.duration.toInt(),
            value: tempBasal.absolute));
      }

      var tempBasalUpdates = await TempBasal.createOrUpdate(tempBasals);

      List<TempTarget> tempTargets = [];
      for (var tempTarget in summary.targets.targets) {
        tempTargets.add(TempTarget(
            startDate: tempTarget.date,
            duration: tempTarget.duration,
            targetTop: tempTarget.targetTop,
            targetBottom: tempTarget.targetBottom));
      }

      var tempTargetUpdates = await TempTarget.createOrUpdate(tempTargets);

      SummaryProfile summaryProfile = summary.profile;

      Profile profile = Profile(
        date: DateTime.now(),
        dia: summaryProfile.dia,
        units: summaryProfile.units,
        timezone: summaryProfile.timezone,
        carbratio: summaryProfile.expandedCarbratio(),
        sens: summaryProfile.expandedSens(),
        basal: summaryProfile.expandedBasal(),
        targetLow: summaryProfile.expandedTargetLow(),
        targetHigh: summaryProfile.expandedTargetHigh(),
      );
      var profileUpdate = await Profile.createOrUpdate(profile);

      print(
          "updateSummary $sgvUpdates, $bolusUpdates, $carbUpdates, $tempBasalUpdates, $tempTargetUpdates, $profileUpdate");

      notifyListeners();
    });
  }
}
