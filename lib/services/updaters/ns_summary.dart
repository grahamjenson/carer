import 'dart:async';

import 'package:carer/models/profile.dart';
import 'package:carer/models/state_data.dart';
import 'package:carer/nsclient/nsclient.dart';
import 'package:carer/nsclient/summary.dart';
import 'package:carer/services/settings/settings.dart';
import 'package:carer/services/updaters/updater.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/utils/logs.dart';
import 'package:clock/clock.dart';

class NSSummaryUpdater extends Updater {
  NSSummaryUpdater() : super(intervalToCheck: const Duration(seconds: 1), maxAgeBeforeChecking: const Duration(seconds: 15)) {
    aeffect(() {
      // Check signal to register
      var _ = Settings().nightscoutURL;
      addExternalReason("NS URL updated");
    });
  }

  @override
  Future<bool> update() async {
    var (nsURL, nsToken) = Settings().nightscoutURLAndToken;
    var (summary, err) = await go(NSClient().getSummary(nsURL, nsToken));

    if (err != null || summary == null) {
      return false;
    }

    // convert the summary to models
    // List<SGV> sgvs = [];
    // for (var sgv in summary.sgvs.sgvs) {
    //   sgvs.add(SGV(value: sgv.sgv, date: sgv.mills));
    // }
    // var sgvUpdates = await SGV.saveAll(sgvs);

    // List<Bolus> boluses = [];
    // for (var bolus in summary.treatments.boluses()) {
    //   boluses.add(Bolus(value: bolus.insulin!, date: bolus.date));
    // }
    // int bolusUpdates = await Bolus.saveAll(boluses);

    // List<Carbs> carbs = [];
    // for (var carb in summary.treatments.carbs()) {
    //   carbs.add(Carbs(value: carb.carbs!.round(), date: carb.date));
    // }
    // int carbUpdates = await Carbs.saveAll(carbs);

    // List<TempBasal> tempBasals = [];
    // for (var tempBasal in summary.tempBasals.tempBasals) {
    //   tempBasals.add(TempBasal(startDate: tempBasal.start, duration: tempBasal.duration.toInt(), value: tempBasal.absolute));
    // }
    // int tempBasalUpdates = await TempBasal.saveAll(tempBasals);

    // List<TempTarget> tempTargets = [];
    // for (var tempTarget in summary.targets.targets) {
    //   tempTargets.add(TempTarget(
    //       startDate: tempTarget.start, duration: tempTarget.duration, highTarget: tempTarget.targetTop, lowTarget: tempTarget.targetBottom));
    // }
    // int tempTargetUpdates = await TempTarget.saveAll(tempTargets);

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

    alog('''
updateSummary $profileUpdate

          ''');

    return true;
  }
}
