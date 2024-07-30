import 'dart:io';

import 'package:carer/nsclient/entries.dart';
import 'package:test/test.dart';

import '../test_utils.dart';
import 'fixtures/files.dart';

void main() async {
  await sqfliteTestInit();

  test('NSEntries.fromJson should parse JSON and create NSEntries object', () async {
    final file = File(files["entries_basic"]!);
    final jsonString = await file.readAsString();

    NSEntries entries = NSEntries.fromJson(jsonString);

    expect(entries.entries, isNotEmpty);
    expect(entries.entries.length, equals(1));

    NSEntry entry = entries.entries[0];
    expect(entry.id, equals("65a842f04b47405049900d0"));
    expect(entry.app, equals("AAPS"));
  });

  test('NSEntries.fromJson should parse JSON and create NSEntries object', () async {
    final file = File(files["entries"]!);
    final jsonString = await file.readAsString();

    NSEntries entries = NSEntries.fromJson(jsonString);

    expect(entries.entries, isNotEmpty);
    expect(entries.entries.length, equals(1000));
  });

  test('parsing bad entries will return empty NSEntries object', () async {
    final file = File(files["entries_bad"]!);
    final jsonString = await file.readAsString();

    bool caught = true;
    try {
      NSEntries.fromJson(jsonString);
    } catch (e) {
      expect(e, isA<TypeError>());
      caught = true;
    }

    expect(caught, isTrue);
  });
}
