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
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';

class UpdateCN extends ChangeNotifier {
  SettingsCN settings;

  // When this updates lots of things will change
  int summaryLastUpdatedMS = 0;
  int summaryAgeInSeconds() {
    var dateRetrieved =
        DateTime.fromMillisecondsSinceEpoch(summaryLastUpdatedMS);
    return clock.now().difference(dateRetrieved).inSeconds;
  }

  bool _summaryToBeUpdated = true;
  bool _entriesToBeUpdated = true;

  String _updateReason = "";

  UpdateCN({required this.settings}) {
    Timer.periodic(const Duration(seconds: 1), (Timer t) => update());
    update();

    // If settings update grab latest summary
    effect(() {
      // Check signal to register
      var _ = Settings.nightscoutUrl.signal.value;
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
    if (summaryAgeInSeconds() > 15) {
      _summaryToBeUpdated = true;
      _updateReason = "Age older than 15 ${summaryAgeInSeconds()}s";
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
    var (nsURL, nsToken) = nightscoutURLAndToken.value;
    Summary? summary =
        await NSClient().getSummary(nsURL, nsToken).catchError((e) {
      log("GETTING SUMMARY ERROR: $e, $nsURL");
      _summaryToBeUpdated = true;
      return null;
    });

    if (summary == null) {
      print("Summary is empty, not updating.");
      _summaryToBeUpdated = true;
      return;
    }
    summaryLastUpdatedMS = clock.now().millisecondsSinceEpoch;

    // convert the summary to models
    int sgvUpdates = 0;
    for (var sgv in summary.sgvs.sgvs) {
      var svgModel = SGV(value: sgv.sgv, date: sgv.mills);

      sgvUpdates += (await svgModel.save()) ? 1 : 0;
    }

    int bolusUpdates = 0;
    for (var bolus in summary.treatments.boluses()) {
      var bolusModel = Bolus(value: bolus.insulin!, date: bolus.date);
      sgvUpdates += (await bolusModel.save()) ? 1 : 0;
    }

    int carbUpdates = 0;
    for (var carb in summary.treatments.carbs()) {
      var carbModel = Carbs(value: carb.carbs!.round(), date: carb.date);
      carbUpdates += (await carbModel.save()) ? 1 : 0;
    }

    int tempBasalUpdates = 0;
    for (var tempBasal in summary.tempBasals.tempBasals) {
      var tbModel = TempBasal(
          startDate: tempBasal.start,
          duration: tempBasal.duration.toInt(),
          value: tempBasal.absolute);
      tempBasalUpdates += (await tbModel.upsert()) ? 1 : 0;
    }

    int tempTargetUpdates = 0;
    for (var tempTarget in summary.targets.targets) {
      var ttModel = TempTarget(
          startDate: tempTarget.start,
          duration: tempTarget.duration,
          targetHigh: tempTarget.targetTop,
          targetLow: tempTarget.targetBottom);
      tempTargetUpdates += (await ttModel.upsert()) ? 1 : 0;
    }

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
    bool iob = false, cob = false, battery = false, cage = false;
    if (state.iob != null) {
      iob = await stateData.setIOB(state.iob!.toDouble());
    }
    if (state.cob != null) {
      cob = await stateData.setCOB(state.cob!.toDouble());
    }
    if (state.battery != null) {
      battery = await stateData.setBattery(state.battery!.toDouble());
    }
    if (state.cage != null) {
      cage = await stateData.setCAge(state.cage!.toDouble());
    }

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
    var (nsURL, nsToken) = nightscoutURLAndToken.value;
    var entries =
        await NSClient().getEntries(nsURL, nsToken, 12 * 48).catchError((e) {
      log("GETTING ENTRIES ERROR: $e, $nsURL");

      return NSEntries.empty();
    });

    List<bool> sgvs = [];
    for (var entry in entries.entries) {
      if (entry.sgv == null) {
        continue;
      }
      sgvs.add(await SGV(value: entry.sgv!, date: entry.date).save());
    }

    var total = 0;
    for (var e in sgvs) {
      if (e) {
        total++;
      }
    }

    print("ENTRIEEESSSSS UPDATES $total");
  }
}
