import 'package:carer/sql/carer_db.dart';
import 'package:carer/widgets/insights/stats.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test_utils.dart';

void main() {
  sqfliteTestInit();

  group('SGV', () {
    DateTime now = DateTime(2020, 1, 1, 12);
    Duration min5 = const Duration(minutes: 5);
    Duration hour48 = const Duration(hours: 48);

    setUp(() async {});

    tearDown(() async {
      await (await CarerDB.instance).deleteAll();
    });

    testWidgets('StatsWidget displays correct data',
        (WidgetTester tester) async {
      // Build our app and trigger a frame
      await tester.pumpWidget(const Stats(),
          duration: const Duration(seconds: 10));

      await expectLater(
        find.byType(Stats),
        matchesGoldenFile('../golden_files/stats.png'),
      );
    });
  });
}
