import 'dart:io';

import 'package:carer/nsclient/summary.dart';
import 'package:test/test.dart';

import 'fixtures/files.dart';

void main() {
  test('Summary JSON parsing test', () async {
    final file = File(files["summary"]!);
    final jsonString = await file.readAsString();

    Summary summary = Summary.fromJson(jsonString);

    // Add your assertions here based on your data and the structure of your objects
    expect(summary.sgvs.sgvs.length, equals(73));

    // ... add more assertions as needed
  });

  test('parsing bad summary will error correctly', () async {
    final file = File(files["summary_bad"]!);
    final jsonString = await file.readAsString();

    expect(() => Summary.fromJson(jsonString), throwsException);
  });
}
