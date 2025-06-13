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
  });
}
