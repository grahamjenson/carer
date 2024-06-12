import 'dart:async';
import 'dart:developer';

import 'package:carer/change_notifiers/settings_cn.dart';
import 'package:carer/models/bolus.dart';
import 'package:carer/models/carbs.dart';
import 'package:carer/models/profile.dart';
import 'package:carer/models/sgv.dart';
import 'package:carer/models/state_data.dart';
import 'package:carer/models/tempbasal.dart';
import 'package:carer/models/temptarget.dart';
import 'package:carer/nsclient/entries.dart';
import 'package:carer/nsclient/nsclient.dart';
import 'package:carer/nsclient/summary.dart';
import 'package:flutter/material.dart';

class UpdateCN extends ChangeNotifier {
  SettingsCN settings;

  // When this updates lots of things will change
  final Summary _summary = Summary.empty;
  bool _summaryToBeUpdated = true;
  bool _entriesToBeUpdated = true;

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

    if (_entriesToBeUpdated) {
      // update the last two days of sgs on boot
      updateEntries();
      _entriesToBeUpdated = false;
    }
  }

  checkUpdateSummary() async {
    if (_summary.ageInSeconds() > 15) {
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
    var summary = await NSClient().getSummary(nsURL, nsToken).catchError((e) {
      log("GETTING SUMMARY ERROR: $e, $nsURL");
      _summaryToBeUpdated = true;
      return Summary.empty;
    });

    // convert the summary to models
    List<SGV> sgvs = [];
    for (var sgv in summary.sgvs.sgvs) {
      sgvs.add(SGV(value: sgv.sgv, date: sgv.mills));
    }
    var saveAllSGV = sgvs.map((e) => e.save()).toList();
    int sgvUpdates = (await Future.wait(saveAllSGV)).where((b) => b).length;

    List<Bolus> boluses = [];
    for (var bolus in summary.treatments.boluses()) {
      boluses.add(Bolus(value: bolus.insulin!, date: bolus.date));
    }
    var saveAllBolus = boluses.map((e) => e.save()).toList();
    int bolusUpdates = (await Future.wait(saveAllBolus)).where((b) => b).length;

    List<Carbs> carbs = [];
    for (var carb in summary.treatments.carbs()) {
      carbs.add(Carbs(value: carb.carbs!.round(), date: carb.date));
    }
    var saveAllCarbs = carbs.map((e) => e.save()).toList();
    int carbUpdates = (await Future.wait(saveAllCarbs)).where((b) => b).length;

    List<TempBasal> tempBasals = [];
    for (var tempBasal in summary.tempBasals.tempBasals) {
      tempBasals.add(TempBasal(
          startDate: tempBasal.start,
          duration: tempBasal.duration.toInt(),
          value: tempBasal.absolute));
    }

    var saveAllTBs = tempBasals.map((e) => e.upsert()).toList();
    int tempBasalUpdates =
        (await Future.wait(saveAllTBs)).where((b) => b).length;

    List<TempTarget> tempTargets = [];
    for (var tempTarget in summary.targets.targets) {
      tempTargets.add(TempTarget(
          startDate: tempTarget.start,
          duration: tempTarget.duration,
          targetHigh: tempTarget.targetTop,
          targetLow: tempTarget.targetBottom));
    }

    var saveAllTTs = tempTargets.map((e) => e.upsert()).toList();
    int tempTargetUpdates =
        (await Future.wait(saveAllTTs)).where((b) => b).length;

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
    var profileUpdate = await profile.save();

    var state = summary.state;
    var stateData = await StateData.instance;
    var iob = await stateData.setIOB(state.iob);
    var cob = await stateData.setCOB(state.cob.toDouble());
    var battery = await stateData.setBattery(state.battery.toDouble());
    var cage = await stateData.setCAge(state.cage.toDouble());

    // summary is not trustworthy source of information
    // TODO replace summary as the source of information
    var badTempBasals = await TempBasal.fixData();
    var badTempTargets = await TempTarget.fixData();

    print('''
updateSummary $sgvUpdates, $bolusUpdates, $carbUpdates, $tempBasalUpdates, $tempTargetUpdates, $profileUpdate, $iob, $cob, $battery, $cage
Bad data $badTempBasals, $badTempTargets
          ''');

    if (cage ||
        cob ||
        iob ||
        battery ||
        profileUpdate ||
        tempBasalUpdates > 0 ||
        tempTargetUpdates > 0 ||
        sgvUpdates > 0 ||
        bolusUpdates > 0 ||
        carbUpdates > 0) {
      print("notifiying change listeners");
      notifyListeners();
    }
  }

  void updateEntries() async {
    var (nsURL, nsToken) = settings.nightscoutURLAndToken;
    var entries =
        await NSClient().getEntries(nsURL, nsToken, 12 * 48).catchError((e) {
      log("GETTING ENTRIES ERROR: $e, $nsURL");
      _summaryToBeUpdated = true;
      return NSEntries.empty();
    });

    List<SGV> sgvs = [];
    for (var entry in entries.entries) {
      if (entry.sgv == null) {
        continue;
      }
      sgvs.add(SGV(value: entry.sgv!, date: entry.date));
    }
    var saveAllSGV = sgvs.map((e) => e.save()).toList();
    int sgvUpdates = (await Future.wait(saveAllSGV)).where((b) => b).length;
    print("ENTRIEEESSSSS UPDATES $sgvUpdates");
  }
}
