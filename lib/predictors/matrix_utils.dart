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
