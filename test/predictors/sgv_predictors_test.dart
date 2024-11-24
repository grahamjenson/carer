import 'package:carer/models/clean_sgv.dart';
import 'package:carer/predictors/sgv_predictors.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_utils.dart';

void main() async {
  agroup('Linear Prediction', () {
    atest("Linear2Predictor", (DateTime now) async {
      await createSVGs([
        (180, min20),
        (170, min15),
        (160, min10),
        (150, min5),
        (140, min0),
        // Clearly should be 130 then 120-ish
      ]);

      Exp2Predictor pr = Exp2Predictor();
      pr.init(lastSGVs: CleanSGV.last3Hours.value);
      var sgvs = pr.predictNextHour();

      expect(sgvs.length, 60);

      var firstSGV = sgvs[4];
      var secondSGV = sgvs[9];
      expect(firstSGV.value, 130);
      expect(firstSGV.date, now.add(min5));
      expect(secondSGV.value, 121);
      expect(secondSGV.date, now.add(min10));
    });
  });
}
