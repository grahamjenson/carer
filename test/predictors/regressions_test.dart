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
}
