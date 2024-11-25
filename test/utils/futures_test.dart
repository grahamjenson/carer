import 'package:carer/utils/env.dart';
import 'package:carer/utils/futures.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_utils.dart';

void main() async {
  agroup("go", () {
    setUp(() async {
      Env.catchErrors = false;
    });

    tearDown() {
      Env.catchErrors = true;
    }

    atest("go works", () async {
      var (x, err) = await go(Future.value(1), name: "t1");
      expect(x, 1);
      expect(err, null);
      (x, err) = await go(Future(() {
        throw "ThisError";
      }), name: "t2");
      expect(x, null);
      expect(err, "ThisError");
    });

    atest("go profiles", () async {
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

  agroup("executeWithRetry", () {
    atest("executeWithRetry works", () async {
      var x = await executeWithRetry(() => Future.value(1));
      expect(x, 1);

      var y;
      Object? err;
      try {
        y = await executeWithRetry(() async {
          throw "ThisError";
        });
      } catch (e) {
        err = e;
      }
      expect(y, null);
      expect(err, "ThisError");

      bool shouldThrow = true;
      x = await executeWithRetry(() async {
        if (shouldThrow) {
          shouldThrow = false;
          throw "ThisError";
        }
        return 1;
      });
      expect(x, 1);
      expect(shouldThrow, false);
    });
  });
}
