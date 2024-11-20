import 'dart:io';

import 'package:carer/nsclient/summary.dart';
import 'package:test/test.dart';

import '../test_utils.dart';
import 'fixtures/files.dart';

void main() async {
  agroup('Summary', () {
    atest('Summary JSON parsing test', () async {
      final file = File(files["summary"]!);
      final jsonString = await file.readAsString();

      Summary? summary = Summary.fromJson(jsonString);

      expect(summary!.sgvs.sgvs.length, equals(13));
    });

    atest('parsing bad summary return enmpty Summary object', () async {
      final file = File(files["summary_bad"]!);
      final jsonString = await file.readAsString();

      bool caught = false;
      try {
        Summary.fromJson(jsonString);
      } catch (e) {
        expect(e, isA<TypeError>());
        caught = true;
      }

      expect(caught, isTrue);
    });
  });
}
