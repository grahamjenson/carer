Future<T> futureProfile<T>(String name, Future<T> toMeasure) {
  Future<T> x = Future(() {
    var stopwatch = Stopwatch()..start();
    return stopwatch;
  }).then((sw) async => (sw, await toMeasure)).then((d) {
    var (sw, r) = d;
    //
    print('$name executed in ${sw.elapsed.inMilliseconds}ms');
    //
    return r;
    //
  });

  return x;
}
