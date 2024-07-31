import 'dart:io';

import 'package:carer/nsclient/treatments.dart';
import 'package:test/test.dart';

import '../test_utils.dart';
import 'fixtures/files.dart';

void main() async {
  await sqfliteTestInit();

  test('basic_treatments parse check', () async {
    final file = File(files["treatments_basic"]!);
    final jsonString = await file.readAsString();

    NSTreatments treatments = NSTreatments.fromJson(jsonString);

    expect(treatments.treatments, isA<List<NSTreatment>>());
    expect(treatments.treatments.length, equals(1));

    NSTreatment firstNSTreatment = treatments.treatments[0];
    expect(firstNSTreatment, isA<NSTreatmentCarbs>());
    var ccc = firstNSTreatment as NSTreatmentCarbs;
    expect(ccc.id, equals("65a83a1c4b474038e0900cf"));
    expect(ccc.carbs, equals(15));
    // Add more assertions as needed for other properties
  });

  test('lots of treatments parse test', () async {
    final file = File(files["treatments"]!);
    final jsonString = await file.readAsString();

    NSTreatments treatments = NSTreatments.fromJson(jsonString);

    expect(treatments.treatments, isA<List<NSTreatment>>());
    expect(treatments.treatments.length, equals(980));
  });

  test('treatments paring bad data will return empty NSTreatments object', () async {
    final file = File(files["treatments_bad"]!);
    final jsonString = await file.readAsString();

    bool caught = false;
    try {
      NSTreatments.fromJson(jsonString);
    } catch (e) {
      expect(e, isA<TypeError>());
      caught = true;
    }
    expect(caught, isTrue);
  });
}
