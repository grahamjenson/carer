import 'package:carer/predictors/lu_decomp.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // example from
  group('LU Decomposistion', () {
    test('decomp', () {
      // example from https://en.wikipedia.org/wiki/LU_decomposition
      var (l, u) = luDecomposition([
        [4, 3],
        [6, 3]
      ]);
      expect(l, [
        [1, 0],
        [1.5, 1]
      ]);
      expect(u, [
        [4, 3],
        [0, -1.5]
      ]);
    });
  });

  // Examples from https://www.gamedev.net/tutorials/programming/math-and-physics/matrix-inversion-using-lu-decomposition-r3637/
  group('LU forward and back propogation', () {});

  group('LU solve', () {
    test('solve', () {
      var X = [
        [3.0, -0.1, -0.2],
        [0.1, 7.0, -0.3],
        [0.3, -0.2, 10.0]
      ];
      var Y = [7.85, -19.3, 71.4];
      var (l, u) = luDecomposition(X);
      var solve = luSolve(l, u, Y);

      // Some very small numbers at the bottom so need rounding to 4dp
      solve = solve.map((e) => double.parse(e.toStringAsFixed(4))).toList();
      expect(solve, [3, -2.5, 7]);
    });
  });
}
