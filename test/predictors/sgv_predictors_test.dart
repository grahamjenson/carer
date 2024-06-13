import 'package:carer/models/sgv.dart';
import 'package:carer/predictors/sgv_predictors.dart';
import 'package:carer/sql/carer_db.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_utils.dart';

void main() {
  sqfliteTestInit();

  DateTime now = DateTime(2020, 1, 1, 12);

  DateTime min5ago = now.subtract(const Duration(minutes: 5));
  DateTime min10ago = now.subtract(const Duration(minutes: 10));
  DateTime min15ago = now.subtract(const Duration(minutes: 15));
  DateTime min20ago = now.subtract(const Duration(minutes: 20));

  DateTime min5fromNow = now.add(const Duration(minutes: 5));
  DateTime min10fromNow = now.add(const Duration(minutes: 10));

  group('Linear Prediction', () {
    setUp(() async {
      // Will make a linear drop
      expect(await SGV(value: 140, date: now).save(), true);
      expect(await SGV(value: 150, date: min5ago).save(), true);
      expect(await SGV(value: 160, date: min10ago).save(), true);
      expect(await SGV(value: 170, date: min15ago).save(), true);
      expect(await SGV(value: 180, date: min20ago).save(), true);
    });

    tearDown(() async {
      await (await CarerDB.instance).deleteAll();
    });

    test("LinearRegressionPredictor", () async {
      LinearRegressionPredictor pr = LinearRegressionPredictor();
      await pr.init();

      var sgvs = pr.predictNextHour();
      expect(sgvs.length, 12);

      var firstSGV = sgvs[0];
      var secondSGV = sgvs[1];
      expect(firstSGV.value, 130);
      expect(firstSGV.date, min5fromNow);
      expect(secondSGV.value, 120);
      expect(secondSGV.date, min10fromNow);

      var rmse =
          await pr.rmse([epoch(min5fromNow), epoch(min10fromNow)], [140, 140]);
      expect(rmse.toInt(), 15);

      rmse =
          await pr.rmse([epoch(min5fromNow), epoch(min10fromNow)], [130, 120]);
      print("$pr RMSE: $rmse $sgvs");
      expect(rmse.toInt(), 0);
    });
  });
}
