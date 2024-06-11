import 'package:carer/predictors/matrix.dart';
import 'package:carer/predictors/regressions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Polynomial Solve', () {
    test("matrix is correct", () {
      // example from https://people.stfx.ca/bliengme/exceltips/Regression%20Analysis%20using%20Matrix%20Algebra.htm
      var pr = PolynomialRegression(2);
      var x = Matrix.fromColumnList([1, 2, 3, 4, 5, 6]);
      var enhanced = pr.enhanced(x);
      expect(enhanced.matrix, [
        [1, 1, 1],
        [1, 2, 4],
        [1, 3, 9],
        [1, 4, 16],
        [1, 5, 25],
        [1, 6, 36]
      ]);
    });
  });
}
