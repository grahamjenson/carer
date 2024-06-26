import 'package:flutter_test/flutter_test.dart';

import '../../test_utils.dart';

void main() async {
  await sqfliteTestInit();
  group("Alarms", () {
    test("HighAlarm", () {
      expect(1, 1);
    });
  });
}
