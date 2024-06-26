import 'package:carer/sql/carer_db.dart';
import 'package:carer/widgets/insights/stats.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test_utils.dart';

void main() async {
  await sqfliteTestInit();

  group('stats', () {
    setUp(() async {});

    tearDown(() async {
      await (await CarerDB.instance).deleteAll();
    });

    testWidgets('StatsWidget displays correct data', (WidgetTester tester) async {
      await tester.runAsync(() async {
        // Build our app and trigger a frame
        await tester.pumpWidget(
          const MaterialApp(home: Stats()),
          duration: const Duration(seconds: 2),
        );
      });
    });
  });
}
