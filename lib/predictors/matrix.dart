// borrowed from matricies package

class Matrix {
  List<List<double>> matrix = [[]];

  Matrix();
  factory Matrix.fromList(List<List<double>> lists) {
    var m = Matrix();
    m.matrix = lists;
    return m;
  }

  factory Matrix.fromColumnList(List<double> list) {
    var m = Matrix();
    m.matrix = [];
    for (var i = 0; i < list.length; i++) {
      m.matrix.add([list[i]]);
    }
    return m;
  }

  factory Matrix.zero(int row, int column) {
    var m = Matrix();
    m.matrix = generateLists(0, row, column);
    return m;
  }

  factory Matrix.one(int row, int column) {
    var m = Matrix();
    m.matrix = generateLists(1, row, column);
    return m;
  }

  factory Matrix.number(double number, int row, int column) {
    var m = Matrix();
    m.matrix = generateLists(number, row, column);
    return m;
  }

  bool valid() {
    for (var list in matrix) {
      for (var element in list) {
        if (!element.isFinite) {
          return false;
        }
        if (element.isNaN) {
          return false;
        }
      }
    }
    return true;
  }

  @override
  String toString() {
    String matrixToString =
        'Matrix: ${(matrix[0].isEmpty) ? 0 : matrix.length}x${matrix[0].length}\n';
    for (var list in matrix) {
      matrixToString += '$list\n';
    }
    return matrixToString;
  }

  int get rowCount {
    return matrix.length;
  }

  int get columnCount {
    return matrix[0].length;
  }

  int get count {
    return rowCount * columnCount;
  }

  double get max {
    double index = matrix[0][0];
    for (int i = 0; i < rowCount; i++) {
      for (int j = 0; j < columnCount; j++) {
        if (matrix[i][j] > index) {
          index = matrix[i][j];
        }
      }
    }
    return index;
  }

  double get min {
    double index = matrix[0][0];
    for (int i = 0; i < rowCount; i++) {
      for (int j = 0; j < columnCount; j++) {
        if (matrix[i][j] < index) {
          index = matrix[i][j];
        }
      }
    }
    return index;
  }

  List<double> row(int row) {
    return matrix[row];
  }

  List<double> column(int column) {
    List<double> list = [];
    for (var i = 0; i < matrix.length; i++) {
      list.add(matrix[i][column]);
    }
    return list;
  }

  Matrix get transpose {
    return Matrix.fromList(listsTranspose(matrix));
  }

  setRow(List<double> list, int row) {
    if (matrix[row].length == list.length) {
      matrix[row] = list;
    } else {
      print('Failed: Length of list is not match. ');
    }
  }

  setColumn(List<double> list, int column) {
    if (matrix.length == list.length) {
      for (var i = 0; i < matrix.length; i++) {
        matrix[i][column] = list[i];
      }
    } else {
      print('Failed: Length of list is not match. ');
    }
  }

  addRow(List<double> list, int index) {
    matrix.insert(index, list);
  }

  addColumn(List<double> list, int index) {
    for (var i = 0; i < matrix.length; i++) {
      matrix[i].insert(index, list[i]);
    }
  }

  appendRows(Matrix injected) {
    matrix.addAll(injected.matrix);
  }

  appendColumns(Matrix injected) {
    for (var i = 0; i < matrix.length; i++) {
      matrix[i].addAll(injected.matrix[i]);
    }
  }

  deleteRow(int index) {
    matrix.removeAt(index);
  }

  deleteColumn(int index) {
    for (var i = 0; i < matrix.length; i++) {
      matrix[i].removeAt(index);
    }
  }

  deleteRows(List<int> list) {
    int index = 0;
    for (int i in list) {
      matrix.removeAt(i - index);
      index++;
    }
  }

  deleteColumns(List<int> list) {
    int temp = 0;
    for (int index in list) {
      for (var i = 0; i < matrix.length; i++) {
        matrix[i].removeAt(index - temp);
      }
      temp++;
    }
  }

  Matrix operator +(dynamic multi) {
    var result = Matrix();
    result.matrix = [];
    List<double> temp = [];
    if (multi is double || multi is int) {
      for (var i = 0; i < matrix.length; i++) {
        for (var j = 0; j < matrix[i].length; j++) {
          temp.add(matrix[i][j] + multi);
        }
        result.matrix.add(temp);
        temp = [];
      }
    }
    if (multi is Matrix) {
      for (var i = 0; i < matrix.length; i++) {
        for (var j = 0; j < multi.matrix[0].length; j++) {
          temp.add(matrix[i][j] + multi.matrix[i][j]);
        }
        result.matrix.add(temp);
        temp = [];
      }
    }
    return result;
  }

  Matrix operator -(dynamic multi) {
    var result = Matrix();
    result.matrix = [];
    List<double> temp = [];
    if (multi is double || multi is int) {
      for (var i = 0; i < matrix.length; i++) {
        for (var j = 0; j < matrix[i].length; j++) {
          temp.add(matrix[i][j] - multi);
        }
        result.matrix.add(temp);
        temp = [];
      }
    }
    if (multi is Matrix) {
      for (var i = 0; i < matrix.length; i++) {
        for (var j = 0; j < multi.matrix[0].length; j++) {
          temp.add(matrix[i][j] - multi.matrix[i][j]);
        }
        result.matrix.add(temp);
        temp = [];
      }
    }
    return result;
  }

  Matrix operator *(dynamic multi) {
    var result = Matrix();
    result.matrix = [];
    List<double> temp = [];
    if (multi is double || multi is int) {
      for (var i = 0; i < matrix.length; i++) {
        for (var j = 0; j < matrix[i].length; j++) {
          temp.add(matrix[i][j] * multi);
        }
        result.matrix.add(temp);
        temp = [];
      }
    }
    if (multi is Matrix) {
      for (var i = 0; i < matrix.length; i++) {
        for (var j = 0; j < multi.matrix[0].length; j++) {
          temp.add(dotProduct(matrix[i], multi.column(j)));
        }
        result.matrix.add(temp);
        temp = [];
      }
    }
    return result;
  }

  List<double> operator [](dynamic index) {
    if (index is int) {
      if (index >= 0) {
        return matrix[index];
      } else if (index < 0) {
        return column(-index);
      }
    } else if (index == '' || index == ' ') {
      return column(0);
    } else {
      throw Exception(
          'Unable to get a value from this index. You can use an integer or an empty string. ');
    }
    return [];
  }

  void operator []=(dynamic index, List<double> value) {
    if (index is int) {
      if (index >= 0) {
        setRow(value, index);
      } else if (index < 0) {
        setColumn(value, -index);
      }
    } else if (index == '' || index == ' ') {
      setColumn(value, 0);
    } else {
      throw Exception(
          'Unable to assign a value to this index. You can use an integer or an empty string. ');
    }
  }
}

List<List<double>> listsTranspose(List<List<double>> lists) {
  List<List<double>> temp = [];
  int rows = lists.length;
  int columns = lists[0].length;
  temp = List.generate(
      columns,
      (indexRow) =>
          List.generate(rows, (indexColumn) => lists[indexColumn][indexRow]));
  return temp;
}

///

double dotProduct(List<double> firstVector, List<double> secondVector) {
  double result = 0;
  for (var i = 0; i < firstVector.length; i++) {
    result += (firstVector[i] * secondVector[i]);
  }
  return result;
}

List<List<double>> generateLists(double seed, int row, int column) {
  List<List<double>> matrix = [];

  matrix = List.generate(
      row, (indexRow) => List.generate(column, (indexColumn) => seed));
  return matrix;
}

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
