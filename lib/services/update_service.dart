import 'dart:async';
import 'dart:developer';

import 'package:carer/models/bolus.dart';
import 'package:carer/models/carbs.dart';
import 'package:carer/models/profile.dart';
import 'package:carer/models/sgv.dart';
import 'package:carer/models/state_data.dart';
import 'package:carer/models/tempbasal.dart';
import 'package:carer/models/temptarget.dart';
import 'package:carer/nsclient/nsclient.dart';
import 'package:carer/nsclient/summary.dart';
import 'package:carer/services/settings/settings.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/utils/logs.dart';
import 'package:clock/clock.dart';

class UpdateService {
  // When this updates lots of things will change
  int summaryLastUpdatedMS = 0;
  int summaryAgeInSeconds() {
    var dateRetrieved = DateTime.fromMillisecondsSinceEpoch(summaryLastUpdatedMS);
    return clock.now().difference(dateRetrieved).inSeconds;
  }

  bool _summaryToBeUpdated = true;
  bool _entriesToBeUpdated = true;

  String _updateReason = "";

  UpdateService() {
    Timer.periodic(const Duration(seconds: 1), (Timer t) => update());
    update();

    // If settings update grab latest summary
    aeffect(() {
      // Check signal to register
      var _ = Settings().nightscoutURL;
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

  checkUpdateSummary() {
    if (summaryAgeInSeconds() > 15) {
      _summaryToBeUpdated = true;
      _updateReason = "Age older than 15 ${summaryAgeInSeconds()}s";
    }
    var lastSGV = SGV.lastSGV().value;
    if (lastSGV == null) {
      _summaryToBeUpdated = true;
      _updateReason = "Last SGV is null";
      return;
    }

    var sgvage = lastSGV.age.inSeconds;

    // Check more frequently when the SGV is about to expire
    if (sgvage > 305 && sgvage < 320) {
      _summaryToBeUpdated = true;
      _updateReason = "Last SGV older than 300";
    }
  }

  updateSummary() async {
    var (nsURL, nsToken) = Settings().nightscoutURLAndToken;
    var (summary, err) = await go(NSClient().getSummary(nsURL, nsToken));

    if (err != null || summary == null) {
      alog("Err OR Summary is empty");
      _summaryToBeUpdated = true;
      return;
    }

    summaryLastUpdatedMS = clock.now().millisecondsSinceEpoch;

    // convert the summary to models
    List<SGV> sgvs = [];
    for (var sgv in summary.sgvs.sgvs) {
      sgvs.add(SGV(value: sgv.sgv, date: sgv.mills));
    }
    var sgvUpdates = await SGV.saveAll(sgvs);

    List<Bolus> boluses = [];
    for (var bolus in summary.treatments.boluses()) {
      boluses.add(Bolus(value: bolus.insulin!, date: bolus.date));
    }
    int bolusUpdates = await Bolus.saveAll(boluses);

    List<Carbs> carbs = [];
    for (var carb in summary.treatments.carbs()) {
      carbs.add(Carbs(value: carb.carbs!.round(), date: carb.date));
    }
    int carbUpdates = await Carbs.saveAll(carbs);

    List<TempBasal> tempBasals = [];
    for (var tempBasal in summary.tempBasals.tempBasals) {
      tempBasals.add(TempBasal(startDate: tempBasal.start, duration: tempBasal.duration.toInt(), value: tempBasal.absolute));
    }
    int tempBasalUpdates = await TempBasal.saveAll(tempBasals);

    List<TempTarget> tempTargets = [];
    for (var tempTarget in summary.targets.targets) {
      tempTargets.add(TempTarget(
          startDate: tempTarget.start, duration: tempTarget.duration, highTarget: tempTarget.targetTop, lowTarget: tempTarget.targetBottom));
    }
    int tempTargetUpdates = await TempTarget.saveAll(tempTargets);

    SummaryProfile summaryProfile = summary.profile;

    Profile profile = Profile(
      date: clock.now(),
      dia: summaryProfile.dia,
      units: summaryProfile.units,
      timezone: summaryProfile.timezone,
      carbratio: summaryProfile.expandedCarbratio(),
      sens: summaryProfile.expandedSens(),
      basal: summaryProfile.expandedBasal(),
      lowTarget: summaryProfile.expandedTargetLow(),
      highTarget: summaryProfile.expandedTargetHigh(),
    );
    var profileUpdate = await profile.save();

    var state = summary.state;

    if (state.iob != null) {
      StateData().setIOB(state.iob!.toDouble());
    }
    if (state.cob != null) {
      StateData().setCOB(state.cob!.toDouble());
    }
    if (state.battery != null) {
      StateData().setBattery(state.battery!.toDouble());
    }
    if (state.cage != null) {
      StateData().setCAge(state.cage!.toDouble());
    }

    // summary is not trustworthy source of information
    // TODO replace summary as the source of information
    var badTempBasals = await TempBasal.fixData();
    var badTempTargets = await TempTarget.fixData();

    alog('''
updateSummary $sgvUpdates, $bolusUpdates, $carbUpdates, $tempBasalUpdates, $tempTargetUpdates, $profileUpdate
Bad data $badTempBasals, $badTempTargets
          ''');
  }

  void updateEntries() async {
    var (nsURL, nsToken) = Settings().nightscoutURLAndToken;

    var (entries, err) = await go(NSClient().getEntries(nsURL, nsToken, 12 * 48));
    if (err != null || entries == null) {
      alog("Err OR Entries is empty");
      _entriesToBeUpdated = true;
      return;
    }

    List<SGV> sgvs = [];
    for (var entry in entries.entries) {
      if (entry.sgv == null) {
        continue;
      }
      sgvs.add(SGV(value: entry.sgv!, date: entry.date));
    }

    var total = await SGV.saveAll(sgvs);

    alog("updateEntries $total");
  }
}
