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

class Solution {
  late List<double> x;
  late Matrix expandedX;
  late List<double> y;
  late List<double> yValuesProcessed;
  late Matrix beta;
  late String type;
  late double Function(double) fixY;

  Solution({
    required this.x,
    required this.y,
    required this.expandedX,
    required this.yValuesProcessed,
    required this.beta,
    required this.type,
    required this.fixY,
  });

  double get rootMeanSquaredError {
    int count = x.length;
    var errors = [];
    for (int index = 0; index < count; index++) {
      var xVal = x[index];
      var yVal = y[index];
      var prediction = predict(xVal);
      var error = yVal - prediction;

      errors.add(pow(error, 2));
    }

    // root mean squared error = sqrt(sum of squared errors / count)
    // https://en.wikipedia.org/wiki/Root-mean-square_deviation
    return sqrt(errors.reduce((a, b) => a + b) / count);
  }

  double predict(double xValue) {
    double result = (expandedX * beta)[0][0];
    return fixY(result);
  }
}

abstract class Regression {
  late Matrix x = Matrix.zero(1, 1);

  late Matrix y = Matrix.zero(1, 1);

  late Matrix beta = Matrix.zero(1, 1);

  bool logY = false;

  @override
  String toString() => 'Regression';

  Solution train(List<double> xValues, List<double> yValues) {
    assert(
        xValues.length == yValues.length, 'x should have the same length as y');

    x = Matrix.fromColumnList(xValues);

    List<double> yValuesProcessed =
        logY ? yValues.map((v) => log(v)).toList() : yValues;
    y = Matrix.fromColumnList(yValuesProcessed);

    Matrix ones = Matrix.fromColumnList(List.filled(x.rowCount, 1));
    ones.appendColumns(expanded(x));

    Matrix a = ones.transpose * ones;
    Matrix b = ones.transpose * y;

    var (l, u) = luDecomposition(a.matrix);
    var solve = luSolve(l, u, b.column(0));
    beta = Matrix.fromColumnList(solve);

    if (logY) {
      return Solution(
        x: xValues,
        y: yValues,
        expandedX: ones,
        yValuesProcessed: yValuesProcessed,
        beta: beta,
        type: toString(),
        fixY: (double y) => exp(y),
      );
    }
    return Solution(
      x: xValues,
      y: yValues,
      yValuesProcessed: yValuesProcessed,
      expandedX: ones,
      beta: beta,
      type: toString(),
      fixY: (double y) => y,
    );
  }

  Matrix expanded(Matrix x) {
    return x;
  }
}

class PolynomialRegression extends Regression {
  final int degree;

  PolynomialRegression(this.degree);

  @override
  String toString() => 'Polynomial($degree)';

  @override
  Matrix expanded(Matrix x) {
    if (degree <= 1) return x;

    Matrix newX = x;
    for (int i = 2; i <= degree; i++) {
      var firstColumn =
          newX.column(0).map((v) => pow(v, i).toDouble()).toList();
      print('Degree of $i: $firstColumn');
      Matrix degreeOfX = Matrix.fromColumnList(firstColumn);
      newX.appendColumns(degreeOfX);
    }

    return newX;
  }
}

class LogRegression extends Regression {
  LogRegression({required bool logY}) {
    this.logY = logY;
  }

  @override
  String toString() => 'Log${logY ? 'LogY' : ''}';

  @override
  Matrix expanded(Matrix x) {
    Matrix newX = x;

    Matrix logX =
        Matrix.fromColumnList(newX.column(0).map((v) => log(v)).toList());

    newX = newX.appendColumns(logX);

    return newX;
  }
}

class SqrtRegression extends Regression {
  @override
  String toString() => 'Sqrt';

  @override
  Matrix expanded(Matrix x) {
    Matrix newX = x;

    Matrix sqrtX =
        Matrix.fromColumnList(newX.column(0).map((v) => sqrt(v)).toList());
    newX = sqrtX;

    return newX;
  }
}

class ExpRegression extends Regression {
  ExpRegression() {
    logY = true;
  }

  @override
  String toString() => 'Exp';
}

class BestMatchRegression {
  final List<Regression> models;
  Solution? selected;

  BestMatchRegression()
      : models = [
          PolynomialRegression(1),
          PolynomialRegression(2),
          LogRegression(logY: false),
          LogRegression(logY: true),
          SqrtRegression(),
          ExpRegression()
        ];

  @override
  String toString() => 'BestMatchRegression';

  Solution train(List<double> x, List<double> y) {
    List<Solution> solutions = [];
    for (Regression regression in models) {
      solutions.add(regression.train(x, y));
    }

    double minErrorVariance = double.infinity;
    selected = solutions.first;
    for (var sol in solutions) {
      double rootMeanSquaredError = sol.rootMeanSquaredError;
      print('$sol regression, error variance: $rootMeanSquaredError');

      if (rootMeanSquaredError < minErrorVariance) {
        selected = sol;
        minErrorVariance = rootMeanSquaredError;
      }
    }

    print('Best matched model: $selected');
    return selected!;
  }

  double predict(double x) {
    if (selected == null) {
      throw Exception('Model not trained');
    }
    return selected!.predict(x);
  }

  double get rootMeanSquaredError {
    if (selected == null) {
      throw Exception('Model not trained');
    }
    return selected!.rootMeanSquaredError;
  }
}
