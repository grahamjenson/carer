import 'dart:async';

import 'package:carer/models/state_data.dart';
import 'package:carer/nsclient/nsclient.dart';
import 'package:carer/services/settings/secure_settings.dart';
import 'package:carer/services/updaters/updater.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/utils/logs.dart';

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

    var state = summary.state;
    raw = summary.raw;

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

    alog('''updateSummary:
      iob: ${state.iob}
      cob: ${state.cob}
      battery: ${state.battery}
      cage: ${state.cage}
      ''');

    return true;
  }
}
