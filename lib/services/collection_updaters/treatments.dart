import 'package:carer/mappers/ns/bolus.dart';
import 'package:carer/mappers/ns/carbs.dart';
import 'package:carer/mappers/ns/profile.dart';
import 'package:carer/mappers/ns/tempbasal.dart';
import 'package:carer/mappers/ns/temptarget.dart';
import 'package:carer/mappers/sql/bolus.dart';
import 'package:carer/mappers/sql/carbs.dart';
import 'package:carer/mappers/sql/profile.dart';
import 'package:carer/mappers/sql/tempbasal.dart';
import 'package:carer/mappers/sql/temptarget.dart';
import 'package:carer/models/properties_data.dart';
import 'package:carer/models/sql/bolus.dart';
import 'package:carer/models/sql/carbs.dart';
import 'package:carer/models/sql/profile.dart';
import 'package:carer/models/sql/tempbasal.dart';
import 'package:carer/models/sql/temptarget.dart';
import 'package:carer/nsclient/nsclient.dart';
import 'package:carer/nsclient/treatments.dart';
import 'package:carer/services/collection_updaters/collection.dart';
import 'package:carer/services/settings/secure_settings.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/utils/logs.dart';
import 'package:clock/clock.dart';

class NSTreatmentsUpdater extends NSCollection {
  @override
  String getCollectionName() {
    return "treatments";
  }

  @override
  Future<bool> bootstrap() async {
    var (nsURL, nsToken) = SecureSettings().nightscoutURLAndToken;

    // We need to update at least the last 3 hours because:
    // 1. We want a clean last 2 hours
    // 2. assuming the longest temp target would be 1 hour long
    // 3. -2 hours - 1 hour = 3 hours

    var (nsProfileSwitch, _) = await go(NSClient().getProfileSwitches(nsURL, nsToken));
    var (insulinChange, _) = await go(NSClient().getInsulinChange(nsURL, nsToken));
    var (sensorChange, _) = await go(NSClient().getSensorChange(nsURL, nsToken));

    var lookbacktime = clock.hoursAgo(24).millisecondsSinceEpoch;
    var (treatments, err) = await go(NSClient().getTreatments(nsURL, nsToken, lookbacktime));
    treatments ??= NSTreatments.empty();
    alog("Bootstrap Retrieved ${treatments.treatments.length} treatments");

    if (nsProfileSwitch != null) {
      raw.add(nsProfileSwitch.raw);
      treatments.treatments.insert(0, nsProfileSwitch);
    }

    if (insulinChange != null) {
      raw.add(insulinChange.raw);
      treatments.treatments.insert(0, insulinChange);
    }

    if (sensorChange != null) {
      raw.add(sensorChange.raw);
      treatments.treatments.insert(0, sensorChange);
    }

    return processTreatments(treatments);
  }

  @override
  Future<bool> update(int lastModified) async {
    var (nsURL, nsToken) = SecureSettings().nightscoutURLAndToken;

    // We need to update at least the last 3 hours because:
    // 1. We want a clean last 2 hours
    // 2. assuming the longest temp target would be 1 hour long
    // 3. -2 hours - 1 hour = 3 hours

    var (treatments, err) = await go(NSClient().getTreatments(nsURL, nsToken, lastModified));

    if (err != null || treatments == null) {
      return false;
    }

    raw.add(treatments.raw);
    alog("Retrieved ${treatments.treatments.length} treatments");
    return processTreatments(treatments);
  }

  Future<bool> processTreatments(NSTreatments treatments) async {
    List<Bolus> boluses = const NSBolusToBolus().mapAToB(treatments.boluses);
    int bolusUpdates = await SQLToBolus().saveAll(boluses);

    List<Carbs> carbs = const NSCarbsToCarbs().mapAToB(treatments.carbs);
    int carbUpdates = await SQLToCarbs().saveAll(carbs);

    List<TempBasal> tempBasals = const NSTempBasalToTempBasal().mapAToB(treatments.tempBasals);
    int tempBasalUpdates = await SQLToTempBasal().upsertAll(tempBasals);

    List<TempTarget> tempTargets = const NSTempTargettoTempTarget().mapAToB(treatments.tempTargets);
    int tempTargetUpdates = await SQLToTempTarget().upsertAll(tempTargets);

    // get the profileswitches
    List<Profile> profileSwitches = [];
    for (var profileSwitch in treatments.profileSwitches) {
      var source = NSProfileSource.profileSwitch;
      NSProfileToProfileExtras extras = NSProfileToProfileExtras(source, profileSwitch.percentage, profileSwitch.durationInMilliseconds ~/ 1000);
      Profile profileModel = const NSProfileToProfile().aToB((profileSwitch.profile, extras));

      profileSwitches.add(profileModel);
    }
    int profileSwitchUpdates = await SQLToProfile().saveAll(profileSwitches);

    if (bolusUpdates > 0 || carbUpdates > 0 || tempBasalUpdates > 0 || tempTargetUpdates > 0 || profileSwitchUpdates > 0) {
      alog(
          "update Treatments bolus:$bolusUpdates carb:$carbUpdates TB: $tempBasalUpdates TT: $tempTargetUpdates profileSwitches:$profileSwitchUpdates");
    }

    // CAGE and SAGE
    if (treatments.insulinChanges.isNotEmpty) {
      var insulinChange = treatments.insulinChanges.first;
      PropertiesData().cage = insulinChange.date;
      alog("Bootstrap Treatments  insulinChanges: ${insulinChange.date}");
    }

    if (treatments.sensorChanges.isNotEmpty) {
      var sensorChange = treatments.sensorChanges.first;
      PropertiesData().sage = sensorChange.date;
      alog("Bootstrap Treatments  sensorChanges: ${sensorChange.date}");
    }

    // Get the profile, upsert the profile, update current percentage of profile in the KV store

    return true;
  }
}
