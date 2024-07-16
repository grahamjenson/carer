import 'package:carer/models/profile.dart';
import 'package:carer/nsclient/nsclient.dart';
import 'package:carer/nsclient/shared.dart';
import 'package:carer/services/settings/secure_settings.dart';
import 'package:carer/services/updaters/updater.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/utils/logs.dart';
import 'package:clock/clock.dart';

class NSProfileUpdater extends Updater {
  NSProfileUpdater() : super(intervalToCheck: const Duration(seconds: 1), maxAgeBeforeChecking: const Duration(seconds: 60)) {
    lastSuccessfulUpdate = clock.daysAgo(1);
    aeffect(() {
      // Check signal to register
      var _ = SecureSettings().nightscoutURL;
      addExternalReason("NS URL updated");
    });
  }

  @override
  Future<bool> update() async {
    var (nsURL, nsToken) = SecureSettings().nightscoutURLAndToken;

    // Get the last amount of readings with a few extra for certainty
    var (profile, err) = await go(NSClient().getCurrentProfile(nsURL, nsToken));
    if (err != null || profile == null) {
      return false;
    }

    raw = profile.raw ?? "";

    Profile profileModel = fromNSProfile(profile, "CurrentProfile", 100, 0);

    // TODO: Should this be upsert, profiles immutable in nightscout?
    var saved = await profileModel.save();
    alog("Updated Profile $saved");

    return true;
  }
}

Profile fromNSProfile(NSProfile profile, String source, int percent, int duration) {
  return Profile(
    name: profile.name,
    eid: profile.id,
    date: profile.date,
    duration: duration,
    source: source,
    percent: percent,
    dia: profile.dia,
    units: profile.units,
    timezone: profile.timezone,
    carbratio: profile.expandedCarbratio(),
    sens: profile.expandedSens(),
    basal: profile.expandedBasal(),
    lowTarget: profile.expandedTargetLow(),
    highTarget: profile.expandedTargetHigh(),
  );
}
