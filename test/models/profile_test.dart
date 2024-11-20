import 'package:carer/mappers/sql/profile.dart';
import 'package:carer/models/sql/profile.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_utils.dart';

void main() async {
  agroup('Profile', () {
    atest("create", (DateTime now) async {
      var p = Profile(
        name: "Default",
        eid: "EID",
        dia: 5,
        timezone: "asad",
        source: "Test",
        percent: 100,
        duration: 10,
        units: "mmol",
        startDate: now,
        carbratio: List<int>.filled(24, 1),
        sens: List<int>.filled(24, 1),
        basal: List<double>.filled(24, 1),
        lowTarget: List<int>.filled(24, 1),
        highTarget: List<int>.filled(24, 1),
      );
      expect(await SQLToProfile().save(p), true);

      var p1 = await Profile.profile();
      expect(p1, isNotNull);
    });
  });
}
