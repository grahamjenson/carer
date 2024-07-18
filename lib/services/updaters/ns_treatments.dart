import 'package:carer/models/bolus.dart';
import 'package:carer/models/carbs.dart';
import 'package:carer/models/profile.dart';
import 'package:carer/models/tempbasal.dart';
import 'package:carer/models/temptarget.dart';
import 'package:carer/nsclient/nsclient.dart';
import 'package:carer/services/settings/secure_settings.dart';
import 'package:carer/services/updaters/ns_profile.dart';
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
    });
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

    List<Bolus> boluses = [];
    for (var bolus in treatments.boluses) {
      boluses.add(Bolus(
        value: bolus.insulin,
        date: bolus.date,
        eid: bolus.id,
      ));
    }
    int bolusUpdates = await Bolus.saveAll(boluses);

    List<Carbs> carbs = [];
    for (var carb in treatments.carbs) {
      carbs.add(Carbs(
        value: carb.carbs.round(),
        date: carb.date,
        eid: carb.id,
      ));
    }
    int carbUpdates = await Carbs.saveAll(carbs);

    List<TempBasal> tempBasals = [];
    for (var tempBasal in treatments.tempBasals) {
      tempBasals.add(TempBasal(
        startDate: tempBasal.date,
        endDate: tempBasal.date.add(Duration(milliseconds: tempBasal.durationInMilliseconds)),
        duration: tempBasal.durationInMilliseconds ~/ 1000,
        value: tempBasal.absolute,
        eid: tempBasal.id,
      ));
    }
    int tempBasalUpdates = await TempBasal.upsertAll(tempBasals);

    List<TempTarget> tempTargets = [];
    for (var tempTarget in treatments.tempTargets) {
      tempTargets.add(TempTarget(
          eid: tempTarget.id,
          startDate: tempTarget.date,
          endDate: tempTarget.date.add(Duration(milliseconds: tempTarget.durationInMilliseconds)),
          duration: tempTarget.durationInMilliseconds ~/ 1000,
          highTarget: tempTarget.targetTop.toInt(),
          lowTarget: tempTarget.targetBottom.toInt()));
    }

    int tempTargetUpdates = await TempTarget.upsertAll(tempTargets);

    // get the profileswitches
    List<Profile> profileSwitches = [];
    for (var profileSwitch in treatments.profileSwitchs) {
      profileSwitches
          .add(fromNSProfile(profileSwitch.profile, profileSwitch.source, profileSwitch.percentage, profileSwitch.durationInMilliseconds ~/ 1000));
    }
    int profileSwitchUpdates = await Profile.saveAll(profileSwitches);

    // Get the profile, upsert the profile, update current percentage of profile in the KV store

    alog('''
  update Treatments 
      bolus:$bolusUpdates
      carb:$carbUpdates
      TB: $tempBasalUpdates
      TT: $tempTargetUpdates
      profileSwitches:$profileSwitchUpdates
          ''');

    return true;
  }
}
