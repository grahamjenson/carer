import 'dart:io';

import 'package:carer/nsclient/entries.dart';
import 'package:test/test.dart';

import 'fixtures/files.dart';

void main() {
  test('Entries.fromJson should parse JSON and create Entries object',
      () async {
    final file = File(files["basic_entries"]!);
    final jsonString = await file.readAsString();

    Entries entries = Entries.fromJson(jsonString);

    expect(entries.entries, isNotEmpty);
    expect(entries.entries.length, equals(1));

    Entry entry = entries.entries[0];
    expect(entry.id, equals("65a842f04b47405049900d0"));
    expect(entry.app, equals("AAPS"));
    // ... add more expectations for other properties
  });

  test('Entries.fromJson should parse JSON and create Entries object',
      () async {
    final file = File(files["entries"]!);
    final jsonString = await file.readAsString();

    Entries entries = Entries.fromJson(jsonString);

    expect(entries.entries, isNotEmpty);
    expect(entries.entries.length, equals(1000));
  });
}
