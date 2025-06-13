import 'package:carer/mappers/ns/profile.dart';
import 'package:carer/mappers/sql/profile.dart';
import 'package:carer/models/sql/profile.dart';
import 'package:carer/nsclient/nsclient.dart';
import 'package:carer/nsclient/shared.dart';
import 'package:carer/services/settings/secure_settings.dart';
import 'package:carer/services/updaters/updater.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/utils/logs.dart';
import 'package:clock/clock.dart';

class NSProfileUpdater extends Updater {
  NSProfileUpdater() : super(intervalToCheck: const Duration(seconds: 60), maxAgeBeforeChecking: const Duration(seconds: 120)) {
    lastSuccessfulUpdate = clock.daysAgo(1);
    aeffect(() {
      // Check signal to register
      var _ = SecureSettings().nightscoutURLAndToken;
      addExternalReason("NS URL updated");
    }, debugLabel: "NSProfileUpdaterReason-NSURL");

    aeffect(() {
      addExternalReason("Resumed");
    }, debugLabel: "NSProfileUpdaterReason-LastResumed");
  }

  @override
  Future<bool> update() async {
    var (nsURL, nsToken) = SecureSettings().nightscoutURLAndToken;

    // Get the last amount of readings with a few extra for certainty
    // TODO return default profile, other profiles and raw seperately
    var (profileProfiles, err) = await go(NSClient().getCurrentProfiles(nsURL, nsToken));

    if (err != null || profileProfiles == null) {
      alog("NSProfileUpdater: Failed to retrieve profiles: $err");
      return false;
    }

    var (currentProfile, otherProfiles, rawr) = profileProfiles;
    raw = rawr;
    if (currentProfile == null) {
      alog("NSProfileUpdater: Failed to retrieve current profile");
      return false;
    }

    // Assigning Duration as 100 years in seconds
    NSProfileToProfileExtras extras = const NSProfileToProfileExtras(NSProfileSource.defaultStoreProfile, 100, 0);
    Profile profileModel = const NSProfileToProfile().aToB((currentProfile, extras));

    // TODO: Should this be upsert, profiles immutable in nightscout?
    var saved = await SQLToProfile().save(profileModel);
    if (saved) {
      alog("NSProfileUpdater: Saved Current Default Profile ${profileModel.name} with ID ${profileModel.eid}");
    } else {
      alog("NSProfileUpdater: Failed to save Current Default Profile ${profileModel.name} with ID ${profileModel.eid}");
    }

    for (NSProfile p in otherProfiles) {
      // Convert each profile to a Profile model
      var extras = const NSProfileToProfileExtras(NSProfileSource.storeProfile, 100, 0);
      var profile = const NSProfileToProfile().aToB((p, extras));

      // Save each profile
      var saved = await SQLToProfile().save(profile);
      if (saved) {
        alog("NSProfileUpdater: Saved Current Default Profile ${profile.name} with ID ${profile.eid}");
      } else {
        alog("NSProfileUpdater: Failed to save Current Default Profile ${profile.name} with ID ${profile.eid}");
      }
    }

    return true;
  }
}
