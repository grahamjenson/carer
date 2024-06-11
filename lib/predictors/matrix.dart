////
// Borrowed from the 'matrices' package
////
library;

import 'package:carer/predictors/matrix_utils.dart';

class Matrix {
  List<List<double>> matrix = [[]];

  Matrix(); // 默认不使用，仅作为脚手架
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
