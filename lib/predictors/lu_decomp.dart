import 'package:carer/predictors/matrix_utils.dart';

(List<List<double>>, List<List<double>>) luDecomposition(
    List<List<double>> matrix) {
  List<List<double>> L = generateLists(0, matrix.length, matrix.length);

  for (int i = 0; i < L.length; i++) {
    L[i][i] = 1;
  }

  List<List<double>> U = generateLists(0, matrix.length, matrix.length);

  for (int i = 0; i < matrix.length; i++) {
    L[i][0] = matrix[i][0] / matrix[0][0];
    U[0][i] = matrix[0][i];

    if (L[i][0].isInfinite || L[i][0].isNaN) {
      return ([], []);
    }
  }

  int pos = 0;
  while (pos < matrix.length) {
    for (int col = pos; col < matrix[0].length; col++) {
      double sumCurrent = 0;
      for (int k = 0; k < pos; k++) {
        sumCurrent += L[pos][k] * U[k][col];
      }
      U[pos][col] = matrix[pos][col] - sumCurrent;
    }

    for (int row = pos + 1; row < matrix.length; row++) {
      double sumCurrent = 0;
      for (int k = 0; k < pos; k++) {
        sumCurrent += L[row][k] * U[k][pos];
      }
      L[row][pos] = (matrix[row][pos] - sumCurrent) / U[pos][pos];

      if (L[row][pos].isInfinite || L[row][pos].isNaN) {
        return ([], []);
      }
    }
    pos++;
  }
  return (L, U);
}

List<double> forwardSub(List<List<double>> l, List<double> b) {
  int n = l.length;
  List<double> x = List<double>.filled(n, 0.0);
  for (int i = 0; i < n; i++) {
    double tmp = b[i];
    for (int j = 0; j < i; j++) {
      tmp -= l[i][j] * x[j];
    }
    x[i] = tmp / l[i][i];
  }
  return x;
}

List<double> backSub(List<List<double>> u, List<double> b) {
  int n = u.length;
  List<double> x = List<double>.filled(n, 0.0);
  for (int i = n - 1; i >= 0; i--) {
    double tmp = b[i];
    for (int j = i + 1; j < n; j++) {
      tmp -= u[i][j] * x[j];
    }
    x[i] = tmp / u[i][i];
  }
  return x;
}

List<double> luSolve(
    List<List<double>> l, List<List<double>> u, List<double> b) {
  List<double> y = forwardSub(l, b);
  List<double> x = backSub(u, y);
  return x;
}
