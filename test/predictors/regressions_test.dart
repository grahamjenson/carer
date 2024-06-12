import 'package:carer/predictors/regressions.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_utils.dart';

void main() {
  group('Polynomial Solve', () {
    test("degree 2 matrices and predictions", () {
      // example from https://people.stfx.ca/bliengme/exceltips/Regression%20Analysis%20using%20Matrix%20Algebra.htm
      List<double> x = [1, 2, 3, 4, 5, 6];
      List<double> y = [0.5, 2.0, 7.5, 17.0, 30.5, 48];
      var pr = PolynomialRegression(x, y, 2);

      expect(pr.expandedX.matrix, [
        [1, 1, 1],
        [1, 2, 4],
        [1, 3, 9],
        [1, 4, 16],
        [1, 5, 25],
        [1, 6, 36]
      ]);

      expect(pr.beta.column(0).map(dp4).toList(), [3, -4.5, 2]);

      expect(dp4(pr.predict(10)), 3 + (-4.5 * 10) + (2 * 100));

      expect(dp4(pr.predict(20)), 3 + (-4.5 * 20) + (2 * 400));

      var (rmse, predictions) = pr.rootMeanSquaredError(x, y);
      expect(dp4(rmse), 0.0);
      expect(predictions.map(dp4).toList(), y);
    });

    test("degree 1 matrices and predictions", () {
      // example from https://people.stfx.ca/bliengme/exceltips/Regression%20Analysis%20using%20Matrix%20Algebra.htm
      List<double> x = [1, 2, 3, 4, 5, 6];
      List<double> y = [0.5, 2.0, 7.5, 17.0, 30.5, 48];
      var pr = PolynomialRegression(x, y, 1);

      expect(pr.expandedX.matrix, [
        [1, 1],
        [1, 2],
        [1, 3],
        [1, 4],
        [1, 5],
        [1, 6]
      ]);

      expect(pr.beta.column(0).map(dp4).toList(), [-15.667, 9.5]);

      expect(dp4(pr.predict(1)), -15.667 + (9.5 * 1));

      expect(dp4(pr.predict(20)), -15.667 + (9.5 * 20));

      expect(dp4(pr.predict(10)), -15.667 + (9.5 * 10));

      expect(dp4(pr.predict(20)), -15.667 + (9.5 * 20));

      var (rmse, _) = pr.rootMeanSquaredError(x, y);
      expect(dp4(rmse), 4.989);
    });
  });

  group("BestMatchRegression", () {
    test("selectes the correct model per dataset", () {
      List<double> flatx = [1, 2, 3, 4, 5, 6];
      List<double> flaty = [11, 11, 11, 11, 11, 11];
      expect(
          BestMatchRegression(flatx, flaty).selected.toString(), 'Flat(11.0)');

      // y = 10x + 1
      List<double> linearx = [1, 2, 3, 4, 5, 6];
      List<double> lineary = [11, 21, 31, 41, 51, 61];
      expect(BestMatchRegression(linearx, lineary).selected.toString(),
          startsWith("Gradient"));

      // y = 3x^2 + 2x + 1
      List<double> poly2x = [1, 2, 3, 4, 5, 6];
      List<double> poly2y = [6, 17, 34, 57, 86, 121];
      expect(BestMatchRegression(poly2x, poly2y).selected.toString(),
          'Polynomial(2)');

      // y = log(x) * 20
      List<double> logx = [1, 2, 3, 4, 5, 6];
      List<double> logy = [0, 6.02, 9.54, 12.04, 13.98, 15.56];
      expect(BestMatchRegression(logx, logy).selected.toString(), 'Log');

      // y = sqrt(x) * 20 + 3
      List<double> sqrtx = [1, 2, 3, 4, 5, 6];
      List<double> sqrty = [
        23,
        31.28427125,
        37.64101615,
        43,
        47.72135955,
        51.98979486
      ];
      expect(BestMatchRegression(sqrtx, sqrty).selected.toString(), 'Sqrt');

      // y = exp(x) * 20 + 3
      List<double> expx = [1, 2, 3, 4, 5, 6];
      List<double> expy = [
        57.36563657,
        150.781122,
        404.7107385,
        1094.963001,
        2971.263182,
        8071.57587
      ];
      expect(BestMatchRegression(expx, expy).selected.toString(), 'Exp');

      // y = 2^x * 20 + 3
      List<double> loglogx = [1, 2, 3, 4, 5, 6];
      List<double> loglogy = [43, 83, 163, 323, 643, 1283];
      expect(
          BestMatchRegression(loglogx, loglogy).selected.toString(), 'LogLog');
    });
  });
}
