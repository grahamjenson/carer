// This class only runs at startup to bootstrap some things like the profile switches

import 'package:carer/mappers/ns/profile.dart';
import 'package:carer/mappers/sql/profile.dart';
import 'package:carer/models/sql/profile.dart';
import 'package:carer/nsclient/nsclient.dart';
import 'package:carer/nsclient/treatments.dart';
import 'package:carer/services/settings/secure_settings.dart';
import 'package:carer/services/updaters/updater.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/utils/logs.dart';

class NsBootstrap extends Updater {
  NsBootstrap()
      : super(
          intervalToCheck: const Duration(seconds: 1),
          maxAgeBeforeChecking: const Duration(seconds: 10),
        );

  @override
  Future<bool> update() => throw UnimplementedError();
  @override
  Future<bool> start() async => throw UnimplementedError();

  Future<bool> bootstrap() async {
    var (nsURL, nsToken) = SecureSettings().nightscoutURLAndToken;

    // We need to update at least the last 3 hours because:
    // 1. We want a clean last 2 hours
    // 2. assuming the longest temp target would be 1 hour long
    // 3. -2 hours - 1 hour = 3 hours

    var (nsProfileSwitches, _) = await go(NSClient().getProfileSwitches(nsURL, nsToken, 1000));
    var (notes, _) = await go(NSClient().getNotes(nsURL, nsToken, 1000));

    List<NSProfileSwitch> switches = [];
    List<String> rawStrs = [];
    if (nsProfileSwitches != null) {
      switches.addAll(nsProfileSwitches.profileSwitches);
      rawStrs.add(nsProfileSwitches.raw);
    }

    if (notes != null) {
      switches.addAll(notes.profileSwitches);
      rawStrs.add(notes.raw);
    }

    raw = "[ ${rawStrs.join(",")} ]";

    // get the profileswitches
    List<Profile> profileSwitches = [];
    for (var profileSwitch in switches) {
      var source = NSProfileSource.profileSwitch;
      NSProfileToProfileExtras extras = NSProfileToProfileExtras(source, profileSwitch.percentage, profileSwitch.durationInMilliseconds ~/ 1000);
      Profile profileModel = const NSProfileToProfile().aToB((profileSwitch.profile, extras));

      profileSwitches.add(profileModel);
    }
    int profileSwitchUpdates = await SQLToProfile().saveAll(profileSwitches);

    // Get the profile, upsert the profile, update current percentage of profile in the KV store

    alog("Bootstrap Treatments  profileSwitches:$profileSwitchUpdates");

    return true;
  }
}
