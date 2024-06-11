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
  late Matrix x = Matrix.zero(1, 1);
  late Matrix y = Matrix.zero(1, 1);
  late Matrix beta = Matrix.zero(1, 1);

  bool logY = false;

  @override
  String toString() => 'Regression';

  double get errorVariance {
    List<double> xValues = x.column(0);
    List<double> yValues =
        logY ? y.column(0).map((v) => exp(v)).toList() : y.column(0);
    int count = xValues.length;

    print('$this errors:');
    for (int index = 0; index < count; index++) {
      print(
          'f(${xValues[index]}) = ${yValues[index]}, predicted: ${predict(xValues[index])}');
    }

    return (List.generate(count,
                (index) => pow(yValues[index] - predict(xValues[index]), 2))
            .reduce((a, b) => a + b) /
        (2 * count));
  }

  void train(List<double> xValues, List<double> yValues) {
    assert(
        xValues.length == yValues.length, 'x should have the same length as y');

    x = Matrix.fromColumnList(xValues);

    List<double> yValuesProcessed =
        logY ? yValues.map((v) => log(v)).toList() : yValues;
    y = Matrix.fromColumnList(yValuesProcessed);

    Matrix newX = enhanced(x);
    Matrix ones = Matrix.fromColumnList(List.filled(x.rowCount, 1));
    Matrix onedNewX = ones.appendColumns(newX);

    Matrix a = onedNewX.transpose * onedNewX;
    Matrix b = onedNewX.transpose * y;

    var (l, u) = luDecomposition(a.matrix);
    var solve = luSolve(l, u, b.column(0));
    beta = Matrix.fromColumnList(solve);
  }

  @override
  double predict(double xValue) {
    Matrix xm = Matrix.fromColumnList([xValue]);
    Matrix newX = enhanced(xm);
    Matrix ones = Matrix.fromColumnList(List.filled(newX.rowCount, 1));
    Matrix onedNewX = ones.appendColumns(newX);

    double result = (onedNewX * beta)[0][0];
    return logY ? exp(result) : result;
  }

  Matrix enhanced(Matrix x) {
    return x;
  }
}

class PolynomialRegression extends Regression {
  final int degree;

  PolynomialRegression(this.degree);

  @override
  String toString() => 'Polynomial($degree)';

  @override
  Matrix enhanced(Matrix x) {
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
  final bool replaceX;

  LogRegression({required this.replaceX, required bool logY}) {
    this.logY = logY;
  }

  @override
  String toString() => 'Log${replaceX ? 'ReplaceX' : ''}${logY ? 'LogY' : ''}';

  @override
  Matrix enhanced(Matrix x) {
    Matrix newX = x;

    Matrix logX =
        Matrix.fromColumnList(newX.column(0).map((v) => log(v)).toList());
    if (replaceX) {
      newX = logX;
    } else {
      newX = newX.appendColumns(logX);
    }

    return newX;
  }
}

class SqrtRegression extends Regression {
  @override
  String toString() => 'Sqrt';

  @override
  Matrix enhanced(Matrix x) {
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
  int selected = 0;

  BestMatchRegression()
      : models = [
          PolynomialRegression(1),
          PolynomialRegression(2),
          LogRegression(replaceX: false, logY: false),
          LogRegression(replaceX: false, logY: true),
          SqrtRegression(),
          ExpRegression()
        ];

  @override
  String toString() => 'BestMatchRegression';

  void train(List<double> x, List<double> y) {
    for (Regression regression in models) {
      regression.train(x, y);
    }

    double minErrorVariance = double.infinity;
    for (int i = 0; i < models.length; i++) {
      double errorVariance = models[i].errorVariance;
      print('${models[i]} regression, error variance: $errorVariance');

      if (errorVariance < minErrorVariance) {
        selected = i;
        minErrorVariance = errorVariance;
      }
    }

    print('Best matched model: ${models[selected]}');
  }

  double predict(double x) {
    return models[selected].predict(x);
  }

  double get errorVariance {
    return models[selected].errorVariance;
  }
}
