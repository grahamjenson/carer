import 'package:carer/mappers/sql/profile.dart';
import 'package:carer/mappers/sql/temptarget.dart';
import 'package:carer/models/sql/profile.dart';
import 'package:carer/models/sql/temptarget.dart';
import 'package:carer/models/valueAtTime.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_utils.dart';

void main() async {
  agroup('ValueAtTime', () {
    atest("getvaluesattime", (DateTime now) async {
      var p = Profile(
        name: "Default",
        eid: "AProfile",
        dia: 5,
        source: "Test",
        percent: 100,
        duration: 0,
        timezone: "asad",
        units: "mmol",
        startDate: now.subtract(hour48),
        carbratio: List<int>.filled(24, 1),
        sens: List<int>.filled(24, 1),
        basal: List<double>.filled(24, 1),
        lowTarget: List<int>.filled(24, 1),
        highTarget: List<int>.filled(24, 2),
      );

      await waitForSignalChange(() async {
        expect(await SQLToProfile().save(p), true);
      }, [ValueAtTime.lastSixHours]);

      var targets = ValueAtTime.lastSixHours.value;

      expect(targets.length, 360); // 5 hours

      valueAssertion(targets[0], lowTarget: 1, highTarget: 2, isTempTarget: false, date: now);

      valueAssertion(targets[1], lowTarget: 1, highTarget: 2, isTempTarget: false, date: now.subtract(min1));

      var tt = TempTarget(
        startDate: now.subtract(
          const Duration(minutes: 1),
        ),
        duration: 300,
        highTarget: 10,
        lowTarget: 5,
        eid: "1",
      );

      await waitForSignalChange(() async {
        expect(await SQLToTempTarget().save(tt), true);
      }, [ValueAtTime.lastSixHours]);

      targets = ValueAtTime.lastSixHours.value;

      expect(targets.length, 360);

      // beginning will be 1 hour ahead
      valueAssertion(targets[0], lowTarget: 5, highTarget: 10, isTempTarget: true, date: now);

      // 3 days of profile targets + 1 temp target
      valueAssertion(targets[1], lowTarget: 1, highTarget: 2, isTempTarget: false, date: now.subtract(min1));
    });
  });
}

void valueAssertion(ValueAtTime v, {int? lowTarget, int? highTarget, bool? isTempTarget, DateTime? date}) {
  if (isTempTarget != null) expect(v.isTempTarget, isTempTarget);
  if (lowTarget != null) expect(v.lowTarget, lowTarget);
  if (highTarget != null) expect(v.highTarget, highTarget);

  if (date != null) expect(v.date, date);
}
