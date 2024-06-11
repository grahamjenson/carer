import 'dart:math';

import 'package:carer/predictors/lu_decomp.dart';
import 'package:carer/predictors/matrix.dart';

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
  }

  double fnY(double y) => y;
  double fnYReverse(double y) => y;
  Matrix expandX(Matrix x);

  @override
  String toString() => 'Regression';

  (double, List<double>) rootMeanSquaredError(
      List<double> testXValues, List<double> testYValues) {
    assert(testXValues.length == testYValues.length,
        'x should have the same length as y');

    int count = testXValues.length;
    var predictions = predictAll(testXValues);

    var errors = [];
    for (int index = 0; index < count; index++) {
      var yVal = testYValues[index];
      var prediction = predictions[index];
      var error = prediction - yVal;
      errors.add(pow(error, 2));
    }

    // root mean squared error = sqrt(sum of squared errors / count)
    // https://en.wikipedia.org/wiki/Root-mean-square_deviation
    var rmse = sqrt(errors.reduce((a, b) => a + b) / count);

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
  late List<double> x;
  late List<double> y;

  late List<Regression> models;
  late Regression selected;

  BestMatchRegression(this.x, this.y) {
    models = [
      PolynomialRegression(x, y, 1),
      PolynomialRegression(x, y, 2),
      // LogRegression(x, y),  // Negative and zero numbers are out
      // LogRegressionLogY(x, y),
      SqrtRegression(x, y),
      // ExpRegression(x, y),
    ];

    double minErrorVariance = double.infinity;
    selected = models.first;
    for (var model in models) {
      // Check the root mean squared error fot
      var (rootMeanSquaredError, _) = model.rootMeanSquaredError(x, y);

      if (rootMeanSquaredError < minErrorVariance) {
        selected = model;
        minErrorVariance = rootMeanSquaredError;
      }
    }
  }

  @override
  String toString() => 'BestMatchRegression';

  double predict(double x) {
    return selected.predict(x);
  }

  double get rootMeanSquaredError {
    var (rmse, _) = selected.rootMeanSquaredError(x, y);
    return rmse;
  }
}
