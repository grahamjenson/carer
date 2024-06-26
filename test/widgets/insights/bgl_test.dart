import 'package:carer/models/sgv.dart';
import 'package:carer/sql/carer_db.dart';
import 'package:carer/widgets/bgl/bgl.dart';
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test_utils.dart';

void main() async {
  await sqfliteTestInit();

  group('bgl', () {
    setUp(() async {});

    tearDown(() async {
      await (await CarerDB.instance).deleteAll();
    });

    testWidgets('BGLWidget displays correct data', (WidgetTester tester) async {
      await tester.runAsync(() async {
        // Build our app and trigger a frame

        await SGV(value: 140, date: clock.now()).save();
        await SGV.lastSGV.future;
        expect(SGV.lastSGV().value!.value, 140);

        await tester.pumpWidget(
          const MaterialApp(home: BGL()),
          duration: const Duration(seconds: 2),
        );
      });

      await expectLater(
        find.byType(BGL),
        matchesGoldenFile('../golden_files/bgl.png'),
      );
    });
  });
}
