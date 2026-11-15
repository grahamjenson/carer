import 'package:carer/mappers/ns/profile.dart';
import 'package:carer/mappers/sql/profile.dart';
import 'package:carer/models/sql/profile.dart';
import 'package:collection/collection.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_utils.dart';

void main() async {
  agroup('Profile', () {
    atest("fetchAllDefaultStoreProfiles", (DateTime now) async {
      var np1 = Profile(
        name: "oldProfile",
        eid: "EID1",
        dia: 5,
        timezone: "asad",
        source: NSProfileSource.defaultStoreProfile.name,
        percent: 100,
        duration: 10,
        units: "mmol",
        startDate: now.subtract(const Duration(hours: 48)),
        carbratio: List<int>.filled(24, 1),
        sens: List<int>.filled(24, 1),
        basal: List<double>.filled(24, 1),
        lowTarget: List<int>.filled(24, 1),
        highTarget: List<int>.filled(24, 1),
      );
      expect(await SQLToProfile().save(np1), true);

      var np2 = Profile(
        name: "newProfile",
        eid: "EID2",
        dia: 5,
        timezone: "asad",
        source: NSProfileSource.defaultStoreProfile.name,
        percent: 100,
        duration: 10,
        units: "mmol",
        startDate: now,
        carbratio: List<int>.filled(24, 2),
        sens: List<int>.filled(24, 2),
        basal: List<double>.filled(24, 2),
        lowTarget: List<int>.filled(24, 2),
        highTarget: List<int>.filled(24, 2),
      );
      expect(await SQLToProfile().save(np2), true);

      var profiles = await Profile.fetchAllDefaultStoreProfiles();

      var t1 = now.subtract(const Duration(hours: 12));
      Profile? oldProfile = profiles.firstWhereOrNull((e) => t1.isAfter(e.startDate));

      var t2 = now.add(const Duration(hours: 12));
      Profile? newProfile = profiles.firstWhereOrNull((e) => t2.isAfter(e.startDate));

      expect(oldProfile, isNotNull);
      expect(newProfile, isNotNull);
      expect(oldProfile!.name, "oldProfile");
      expect(newProfile!.name, "newProfile");
    });

    atest("selectProfileAtTime", (DateTime now) async {
      var agesAgo = now.subtract(const Duration(days: 10));

      var profiles = await Profile.fetchAllDefaultStoreProfiles();
      var profileSwitches = await Profile.fetchProfileSwitches();

      var sp0 = Profile.selectProfileAtTime(now, profiles, profileSwitches);
      expect(sp0, isNull);

      var np1 = Profile(
        name: "profile1",
        eid: "EID1",
        dia: 5,
        timezone: "asad",
        source: NSProfileSource.defaultStoreProfile.name,
        percent: 100,
        duration: 0,
        units: "mmol",
        startDate: now.subtract(const Duration(hours: 10)),
        carbratio: List<int>.filled(24, 1),
        sens: List<int>.filled(24, 1),
        basal: List<double>.filled(24, 1),
        lowTarget: List<int>.filled(24, 1),
        highTarget: List<int>.filled(24, 1),
      );
      expect(await SQLToProfile().save(np1), true);

      profiles = await Profile.fetchAllDefaultStoreProfiles();
      profileSwitches = await Profile.fetchProfileSwitches();

      var sp1 = Profile.selectProfileAtTime(now, profiles, profileSwitches);
      expect(sp1, isNotNull);
      expect(sp1!.name, "profile1");

      var spn1 = Profile.selectProfileAtTime(agesAgo, profiles, profileSwitches);
      expect(spn1, isNull);

      var np2 = Profile(
        name: "profileSwitch1",
        eid: "EID2",
        dia: 5,
        timezone: "asad",
        source: NSProfileSource.profileSwitch.name,
        percent: 100,
        duration: 300,
        units: "mmol",
        startDate: now.subtract(const Duration(hours: 1)),
        carbratio: List<int>.filled(24, 2),
        sens: List<int>.filled(24, 2),
        basal: List<double>.filled(24, 2),
        lowTarget: List<int>.filled(24, 2),
        highTarget: List<int>.filled(24, 2),
      );
      expect(await SQLToProfile().save(np2), true);

      profiles = await Profile.fetchAllDefaultStoreProfiles();
      profileSwitches = await Profile.fetchProfileSwitches();
      print(
          "${profileSwitches[0].name} ${profileSwitches[0].duration}, startDate: ${profileSwitches[0].startDate}, endDate: ${profileSwitches[0].endDate} $now");

      var sp2 = Profile.selectProfileAtTime(now.subtract(const Duration(minutes: 57)), profiles, profileSwitches);
      expect(sp2, isNotNull);
      expect(sp2!.name, "profileSwitch1");

      var spr2 = Profile.selectProfileAtTime(now.subtract(const Duration(minutes: 50)), profiles, profileSwitches);
      expect(spr2, isNotNull);
      expect(spr2!.name, "profile1");
    });
  });
}
