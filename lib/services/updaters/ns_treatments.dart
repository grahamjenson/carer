import 'package:carer/mappers/ns_to_models.dart';
import 'package:carer/mappers/sql_mappers.dart';
import 'package:carer/models/bolus.dart';
import 'package:carer/models/carbs.dart';
import 'package:carer/models/profile.dart';
import 'package:carer/models/tempbasal.dart';
import 'package:carer/models/temptarget.dart';
import 'package:carer/nsclient/nsclient.dart';
import 'package:carer/services/settings/secure_settings.dart';
import 'package:carer/services/updaters/updater.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/utils/logs.dart';
import 'package:clock/clock.dart';

class NSTreatmentsUpdater extends Updater {
  NSTreatmentsUpdater() : super(intervalToCheck: const Duration(seconds: 1), maxAgeBeforeChecking: const Duration(seconds: 10)) {
    lastSuccessfulUpdate = clock.daysAgo(1);
    aeffect(() {
      // Check signal to register
      var _ = SecureSettings().nightscoutURL;
      addExternalReason("NS URL updated");
    }, debugLabel: "NSTreatmentsUpdaterReason");
  }

  @override
  Future<bool> update() async {
    var (nsURL, nsToken) = SecureSettings().nightscoutURLAndToken;

    // We need to update at least the last 3 hours because:
    // 1. We want a clean last 2 hours
    // 2. assuming the longest temp target would be 1 hour long
    // 3. -2 hours - 1 hour = 3 hours
    var gteCreatedAt = super.lastSuccessfulUpdate.subtract(const Duration(minutes: 180));
    var (treatments, err) = await go(NSClient().getTreatments(nsURL, nsToken, gteCreatedAt));

    if (err != null || treatments == null) {
      return false;
    }

    raw = treatments.raw;

    alog("Retrieved ${treatments.treatments.length} treatments");

    List<Bolus> boluses = const NSBolusToBolus().mapAToB(treatments.boluses);
    int bolusUpdates = await SQLToBolus().saveAll(boluses);

    List<Carbs> carbs = const NSCarbstoCarbs().mapAToB(treatments.carbs);
    int carbUpdates = await SQLToCarbs().saveAll(carbs);

    List<TempBasal> tempBasals = const NSTempBasalToTempBasal().mapAToB(treatments.tempBasals);
    int tempBasalUpdates = await SQLToTempBasal().upsertAll(tempBasals);

    List<TempTarget> tempTargets = const NSTempTargettoTempTarget().mapAToB(treatments.tempTargets);
    int tempTargetUpdates = await SQLToTempTarget().upsertAll(tempTargets);

    // get the profileswitches
    List<Profile> profileSwitches = [];
    for (var profileSwitch in treatments.profileSwitchs) {
      NSProfileToProfileExtras extras =
          NSProfileToProfileExtras(profileSwitch.source, profileSwitch.percentage, profileSwitch.durationInMilliseconds ~/ 1000);
      Profile profileModel = const NSProfileToProfile().aToB((profileSwitch.profile, extras));

      profileSwitches.add(profileModel);
    }
    int profileSwitchUpdates = await SQLToProfile().saveAll(profileSwitches);

    // Get the profile, upsert the profile, update current percentage of profile in the KV store

    if (bolusUpdates > 0 || carbUpdates > 0 || tempBasalUpdates > 0 || tempTargetUpdates > 0 || profileSwitchUpdates > 0) {
      alog(
          "update Treatments bolus:$bolusUpdates carb:$carbUpdates TB: $tempBasalUpdates TT: $tempTargetUpdates profileSwitches:$profileSwitchUpdates");
    }
    return true;
  }
}
