import 'dart:io';

import 'package:carer/nsclient/treatments.dart';
import 'package:test/test.dart';

import 'fixtures/files.dart';

void main() {
  test('basic_treatments parse check', () async {
    final file = File(files["treatments_basic"]!);
    final jsonString = await file.readAsString();

    Treatments treatments = Treatments.fromJson(jsonString);

    expect(treatments.treatments, isA<List<Treatment>>());
    expect(treatments.treatments.length, equals(1));

    Treatment firstTreatment = treatments.treatments[0];
    expect(firstTreatment.id, equals("65a83a1c4b474038e0900cf"));
    expect(firstTreatment.app, equals("AAPS"));
    expect(firstTreatment.carbs, equals(15));
    // Add more assertions as needed for other properties
  });

  test('lots of treatments parse test', () async {
    final file = File(files["treatments"]!);
    final jsonString = await file.readAsString();

    Treatments treatments = Treatments.fromJson(jsonString);

    expect(treatments.treatments, isA<List<Treatment>>());
    expect(treatments.treatments.length, equals(552));
  });

  test('treatments paring bad data will return empty Treatments object',
      () async {
    final file = File(files["treatments_bad"]!);
    final jsonString = await file.readAsString();

    Treatments treatments = Treatments.fromJson(jsonString);

    expect(treatments.treatments, isA<List<Treatment>>());
    expect(treatments.treatments.length, equals(0));
  });
}
