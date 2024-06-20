import 'implregressions.dart';

void main() async {
  var b = BestMatchRegression([1, 2, 3], [180, 165, 165]);
  print(b.selected);
  for (var m in b.models) {
    print("$m,${m.predictAll([1, 2, 3, 4, 5, 6]).map(dp4)}");
  }
}

double dp4(num value) {
  if (value.isNaN || value.isInfinite) {
    return value.toDouble();
  }
  return (value * 1000.0).round() / 1000.0;
}
