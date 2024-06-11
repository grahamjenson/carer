import 'dart:math';

import 'package:carer/predictors/lu_decomp.dart';
import 'package:carer/predictors/matrix.dart';
import 'package:carer/utils/math.dart';

extension ListStatistics on List<double> {
  double get average => reduce((a, b) => a + b) / length;
  double get standardDeviation {
    double avg = average;
    return sqrt(map((x) => pow(x - avg, 2)).reduce((a, b) => a + b) / length);
  }
}

abstract class Regression {
  late List<double> xValues;
  late Matrix xM;
  late Matrix expandedX;

  late List<double> yValues;
  late Matrix yM;

  late Matrix beta;
  late double rmse;

  Regression(this.xValues, this.yValues) {
    assert(
        xValues.length == yValues.length, 'x should have the same length as y');

    xM = Matrix.fromColumnList(xValues);

    yM = Matrix.fromColumnList(yValues.map((e) => fnY(e)).toList());

    expandedX = Matrix.fromColumnList(List.filled(xM.rowCount, 1));
    expandedX.appendColumns(expandX(xM));

    Matrix a = expandedX.transpose * expandedX;
    Matrix b = expandedX.transpose * yM;

    var (l, u) = luDecomposition(a.matrix);
    var solve = luSolve(l, u, b.column(0));
    beta = Matrix.fromColumnList(solve);

    rmse = rootMeanSquaredError(xValues, yValues).$1;
  }

  double fnY(double y) => y;
  double fnYReverse(double y) => y;
  Matrix expandX(Matrix x);

  @override
  String toString() => 'Regression';

  (double, List<double>) rootMeanSquaredError(
      List<double> testXValues, List<double> testYValues) {
    var predictions = predictAll(testXValues);
    var rmse = Math.rootMeanSquaredError(testXValues, testYValues, predictions);
    return (rmse, predictions);
  }

  double predict(double xValue) {
    Matrix m = Matrix.fromColumnList([1]);
    m.appendColumns(expandX(Matrix.fromColumnList([xValue])));
    double result = (m * beta)[0][0];
    return fnYReverse(result);
  }

  List<double> predictAll(List<double> xVals) {
    return xVals.map(predict).toList();
  }
}

class PolynomialRegression extends Regression {
  final int degree;

  PolynomialRegression(super.xValues, super.yValues, this.degree);

  @override
  String toString() => 'Polynomial($degree)';

  @override
  Matrix expandX(Matrix x) {
    if (degree <= 1) return x;

    for (int i = 2; i <= degree; i++) {
      var firstColumn = x.column(0).map((v) => pow(v, i).toDouble()).toList();

      Matrix degreeOfX = Matrix.fromColumnList(firstColumn);
      x.appendColumns(degreeOfX);
    }

    return x;
  }
}

class LogRegression extends Regression {
  LogRegression(super.xValues, super.yValues);

  @override
  String toString() => 'Log';

  @override
  Matrix expandX(Matrix x) {
    Matrix logX =
        Matrix.fromColumnList(x.column(0).map((v) => log(v)).toList());

    x.appendColumns(logX);

    return x;
  }
}

class LogRegressionLogY extends Regression {
  LogRegressionLogY(super.xValues, super.yValues);

  @override
  String toString() => 'LogLogY';

  @override
  Matrix expandX(Matrix x) {
    Matrix logX =
        Matrix.fromColumnList(x.column(0).map((v) => log(v)).toList());

    x.appendColumns(logX);

    return x;
  }

  @override
  double fnY(double y) => log(y);

  @override
  double fnYReverse(double y) => exp(y);
}

class SqrtRegression extends Regression {
  SqrtRegression(super.xValues, super.yValues);

  @override
  String toString() => 'Sqrt';

  @override
  Matrix expandX(Matrix x) {
    Matrix sqrtX =
        Matrix.fromColumnList(x.column(0).map((v) => sqrt(v)).toList());
    x = sqrtX;

    return x;
  }
}

class ExpRegression extends Regression {
  ExpRegression(super.xValues, super.yValues);

  @override
  String toString() => 'Exp';
  @override
  expandX(Matrix x) => x;

  @override
  double fnY(double y) => log(y);

  @override
  double fnYReverse(double y) => exp(y);
}

class BestMatchRegression {
  late List<Regression> models;
  late Regression selected;

  BestMatchRegression(List<double> xValues, List<double> yValues) {
    models = [
      PolynomialRegression(xValues, yValues, 1),
      PolynomialRegression(xValues, yValues, 2),
      // LogRegression(xValues, yValues),  // Negative and zero numbers are out
      // LogRegressionLogY(xValues, yValues),
      SqrtRegression(xValues, yValues),
      // ExpRegression(xValues, yValues),
    ];

    double minErrorVariance = double.infinity;
    selected = models.first;
    for (var model in models) {
      // Check the root mean squared error fot
      var rootMeanSquaredError = model.rmse;

      if (rootMeanSquaredError < minErrorVariance) {
        selected = model;
        minErrorVariance = rootMeanSquaredError;
      }
    }
  }

  @override
  String toString() => 'BestMatch($selected)';

  double predict(double x) {
    return selected.predict(x);
  }

  double get rmse => selected.rmse;
}
