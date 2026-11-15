import 'dart:convert';

import 'package:carer/nsclient/ns_type.dart';
import 'package:carer/utils/logs.dart';

class NSEntry {
  String? id;
  DateTime date;

  int sgv;
  String? type;
  String? units;
  int? utcOffset;
  DateTime createdAt;
  String? identifier;

  NSEntry({
    required this.id,
    required this.date,
    required this.sgv,
    required this.type,
    required this.units,
    required this.utcOffset,
    required this.createdAt,
    required this.identifier,
  });

  factory NSEntry.fromJson(Map<String, dynamic> json) {
    var guessDate = NSType.getBestGuessDate(json);

    return NSEntry(
      id: json['identifier'],
      date: guessDate,
      sgv: NSType.getInt(json['sgv'], defaultValue: 0)!,
      type: json['type'],
      units: json['units'],
      utcOffset: NSType.getInt(json['utcOffset']),
      createdAt: guessDate,
      identifier: json['identifier'],
    );
  }

  bool isValidAndComplete() {
    return id != null && sgv != 0;
  }
}

class NSEntries {
  List<NSEntry> entries;
  String raw;
  bool isEmpty() => entries.isEmpty;
  NSEntry? firstOrNull() => entries.firstOrNull;

  int get length => entries.length;
  NSEntry operator [](int index) => entries[index];

  NSEntries({
    required this.entries,
    required this.raw,
  });

  factory NSEntries.empty() {
    return NSEntries(entries: [], raw: "");
  }

  factory NSEntries.fromJson(String jsonStr) {
    try {
      final Map<String, dynamic> jsonObject = json.decode(jsonStr);
      final List<dynamic> jsonList = jsonObject['result'] ?? [];

      List<NSEntry> entries = jsonList.map((json) => NSEntry.fromJson(json)).where((e) => e.isValidAndComplete()).toList();
      entries.sort((a, b) => b.date.compareTo(a.date));

      return NSEntries(entries: entries, raw: jsonStr);
    } catch (e, stackTrace) {
      Errors.captureError(e, stackTrace);
      return NSEntries(entries: [], raw: jsonStr);
    }
  }
}
