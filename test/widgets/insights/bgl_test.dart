import 'package:carer/models/clean_sgv.dart';
import 'package:carer/widgets/bgl/bgl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test_utils.dart';

void main() async {
  agroup('bgl', () {
    atestWidgets('BGLWidget displays correct data', (WidgetTester tester) async {
      await tester.runAsync(() async {
        // Build our app and trigger a frame
        await createSGVsInOrder([140]);

        expect(CleanSGV.lastSGV.value!.value, 140);

        await tester.pumpWidget(
          const MaterialApp(home: BGL()),
          duration: const Duration(seconds: 2),
        );
      });
    });
  });
}
