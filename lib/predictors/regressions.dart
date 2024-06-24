import 'dart:math';

import 'package:carer/predictors/matrix.dart';
import 'package:carer/utils/math.dart';

//  Converted From NightGuard codebase
//  Maybe from https://github.com/dfelber/SwiftRegressionExperiments
//  Created by Dominik Felber on 15.05.16.
//  Copyright © 2016 Dominik Felber. All rights reserved.

extension ListStatistics on List<double> {
  double get average => reduce((a, b) => a + b) / length;
  double get standardDeviation {
    double avg = average;
    return sqrt(map((x) => pow(x - avg, 2)).reduce((a, b) => a + b) / length);
  }
}

abstract class Regression {
  double predict(double xValue);

  List<double> predictAll(List<double> xVals) {
    return xVals.map(predict).toList();
  }

  double get rmse;

  (double, List<double>) rootMeanSquaredError(
      List<double> testXValues, List<double> testYValues) {
    var predictions = predictAll(testXValues);
    var rmse = Math.rootMeanSquaredError(testXValues, testYValues, predictions);
    return (rmse, predictions);
  }
}

class NoopRegression extends Regression {
  @override
  double predict(double xValue) {
    return double.nan;
  }

  @override
  double get rmse => double.nan;
}

abstract class MatrixRegression extends Regression {
  late List<double> xValues;
  late Matrix xM;
  late Matrix expandedX;

  late List<double> yValues;
  late Matrix yM;

  late Matrix beta;
  late double _rmse;

  MatrixRegression(this.xValues, this.yValues) {
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

    _rmse = rootMeanSquaredError(xValues, yValues).$1;
  }

  double fnY(double y) => y;
  double fnYReverse(double y) => y;
  Matrix expandX(Matrix x);

  @override
  double get rmse => _rmse;

  @override
  String toString() => 'Regression';

  @override
  double predict(double xValue) {
    Matrix m = Matrix.fromColumnList([1]);
    m.appendColumns(expandX(Matrix.fromColumnList([xValue])));

    if (!m.valid() || !beta.valid()) {
      return double.nan;
    }

    var resultMatrix = (m * beta);
    return fnYReverse(resultMatrix[0][0]);
  }
}

class PolynomialRegression extends MatrixRegression {
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

class LogRegression extends MatrixRegression {
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

class LogRegressionLogY extends MatrixRegression {
  LogRegressionLogY(super.xValues, super.yValues);

  @override
  String toString() => 'LogLog';

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

class SqrtRegression extends MatrixRegression {
  SqrtRegression(super.xValues, super.yValues);

  @override
  String toString() => 'Sqrt';

  @override
  Matrix expandX(Matrix x) {
    Matrix sqrtX =
        Matrix.fromColumnList(x.column(0).map((v) => sqrt(v)).toList());

    x.appendColumns(sqrtX);

    return x;
  }
}

class ExpRegression extends MatrixRegression {
  ExpRegression(super.xValues, super.yValues);

  @override
  String toString() => 'Exp';

  @override
  Matrix expandX(Matrix x) {
    return x;
  }

  @override
  double fnY(double y) => log(y);

  @override
  double fnYReverse(double y) => exp(y);
}

class FlatRegression extends Regression {
  late double value;
  double _rmse = 0;

  FlatRegression(List<double> xValues, List<double> yValues) {
    value = yValues.first;
    _rmse = rootMeanSquaredError(xValues, yValues).$1;
  }

  @override
  String toString() => 'Flat($value)';

  @override
  double predict(double x) {
    return value;
  }

  @override
  double get rmse => _rmse;
}

class GradientRegression extends Regression {
  late double slope;
  late double c;
  late double _rmse;

  GradientRegression(List<double> x, List<double> y) {
    //y = ax + c
    // x is timestamp, y is the predicted value, c = -ax1 + y1

    slope = (y[1] - y[0]) / (x[1] - x[0]);

    // Calculate c using the formula c = -ax1 + y1
    c = -slope * x[0] + y[0];

    _rmse = rootMeanSquaredError(x, y).$1;
  }

  @override
  String toString() => 'Gradient(${slope}x + $c)';

  @override
  double predict(double x) {
    return slope * x + c;
  }

  @override
  double get rmse => _rmse;
}

class LinearRegression extends PolynomialRegression {
  LinearRegression(List<double> xValues, List<double> yValues)
      : super(xValues, yValues, 1);

  @override
  String toString() => 'Linear';
}

class QuadraticRegression extends PolynomialRegression {
  QuadraticRegression(List<double> xValues, List<double> yValues)
      : super(xValues, yValues, 2);

  @override
  String toString() => 'Quadratic';
}

class BestMatchRegression extends Regression {
  late List<Regression> models;
  late Regression selected;

  BestMatchRegression(List<double> xValues, List<double> yValues) {
    models = [
      FlatRegression(xValues, yValues),
      GradientRegression(xValues, yValues),
      LinearRegression(xValues, yValues),
      QuadraticRegression(xValues, yValues),
      LogRegression(xValues, yValues), // Negative and zero numbers are out
      LogRegressionLogY(xValues, yValues),
      SqrtRegression(xValues, yValues),
      ExpRegression(xValues, yValues),
    ];

    double minErrorVariance = double.infinity;
    selected = models.first;
    for (var model in models) {
      // Check the root mean squared error fot
      var rootMeanSquaredError = model.rmse;

      print("$model RMSE: $rootMeanSquaredError");
      if (rootMeanSquaredError.isNaN) {
        continue;
      }
      if (rootMeanSquaredError < minErrorVariance) {
        selected = model;
        minErrorVariance = rootMeanSquaredError;
      }
    }
  }

  @override
  String toString() => 'BestMatch($selected)';

  @override
  double predict(double x) {
    return selected.predict(x);
  }

  @override
  List<double> predictAll(List<double> xVals) {
    return selected.predictAll(xVals);
  }

  @override
  double get rmse => selected.rmse;

  @override
  (double, List<double>) rootMeanSquaredError(
      List<double> testXValues, List<double> testYValues) {
    return selected.rootMeanSquaredError(testXValues, testYValues);
  }
}
