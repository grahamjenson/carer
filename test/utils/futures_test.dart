import 'package:carer/utils/env.dart';
import 'package:carer/utils/futures.dart';
import 'package:flutter_test/flutter_test.dart';

void main() async {
  group("go", () {
    setUp(() async {
      Env.catchErrors = false;
    });

    tearDown() {
      Env.catchErrors = true;
    }

    test("go works", () async {
      var (x, err) = await go(Future.value(1), name: "t1");
      expect(x, 1);
      expect(err, null);
      (x, err) = await go(Future(() {
        throw "ThisError";
      }), name: "t2");
      expect(x, null);
      expect(err, "ThisError");
    });

    test("go profiles", () async {
      var (x, err) = await go(Future.delayed(const Duration(milliseconds: 100), () => 1), name: "t1", profile: true);
      expect(x, 1);
      expect(err, null);

      (x, err) = await go(Future.delayed(const Duration(milliseconds: 100), () => throw "ThisError"), name: "t1", profile: true);
      expect(x, null);
      expect(err, "ThisError");

      // Expect Stopwatch to have stopped
      // Expect that the profile has been logged
    });
  });
}
