import 'dart:io';

import 'package:carer/nsclient/summary.dart';
import 'package:test/test.dart';

import 'fixtures/files.dart';

void main() {
  test('Summary JSON parsing test', () async {
    final file = File(files["summary"]!);
    final jsonString = await file.readAsString();

    Summary? summary = Summary.fromJson(jsonString);

    expect(summary!.sgvs.sgvs.length, equals(13));
  });

  test('parsing bad summary return enmpty Summary object', () async {
    final file = File(files["summary_bad"]!);
    final jsonString = await file.readAsString();

    Summary? summary = Summary.fromJson(jsonString);

    expect(summary, equals(null));
  });
}
