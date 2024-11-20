import 'dart:io';

import 'package:carer/nsclient/properties.dart';
import 'package:test/test.dart';

import '../test_utils.dart';
import 'fixtures/files.dart';

void main() async {
  agroup('NSProperties', () {
    atest('NSProperties JSON parsing test', () async {
      final file = File(files["properties"]!);
      final jsonString = await file.readAsString();

      NSProperties? properties = NSProperties.fromJson(jsonString);
      expect(properties, isNotNull);
      expect(properties!.battery, equals(87));
      expect(properties.batteryDisplay, equals("87%"));
      expect(properties.iob, equals(1.737));
      expect(properties.basaliob, equals(-0.632));
      expect(properties.treatmentIob, equals(3.264));
      expect(properties.cob, equals(9.39056953071084));
      expect(properties.cannulaChangeTime, equals(1722497000000));
      expect(properties.sensorChangeTime, equals(1722498000000));
    });

    atest('parsing bad NSProperties return enmpty NSProperties object', () async {
      NSProperties? properties = NSProperties.fromJson("{}");

      expect(properties, isNotNull);
      expect(properties!.battery, isNull);
      expect(properties.batteryDisplay, isNull);
      expect(properties.iob, isNull);
      expect(properties.basaliob, isNull);
      expect(properties.treatmentIob, isNull);
      expect(properties.cob, isNull);
      expect(properties.cannulaChangeTime, isNull);
      expect(properties.sensorChangeTime, isNull);
    });
  });
}
