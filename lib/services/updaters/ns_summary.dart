import 'dart:async';

import 'package:carer/models/profile.dart';
import 'package:carer/models/state_data.dart';
import 'package:carer/nsclient/nsclient.dart';
import 'package:carer/nsclient/summary.dart';
import 'package:carer/services/settings/secure_settings.dart';
import 'package:carer/services/updaters/updater.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/utils/logs.dart';
import 'package:clock/clock.dart';

class NSSummaryUpdater extends Updater {
  NSSummaryUpdater() : super(intervalToCheck: const Duration(seconds: 1), maxAgeBeforeChecking: const Duration(seconds: 15)) {
    aeffect(() {
      // Check signal to register
      var _ = SecureSettings().nightscoutURL;
      addExternalReason("NS URL updated");
    });
  }

  @override
  Future<bool> update() async {
    var (nsURL, nsToken) = SecureSettings().nightscoutURLAndToken;
    var (summary, err) = await go(NSClient().getSummary(nsURL, nsToken));

    if (err != null || summary == null) {
      return false;
    }

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

    alog('''updateSummary $profileUpdate''');

    return true;
  }
}
