import 'dart:convert';

import 'package:carer/nsclient/ns_type.dart';
import 'package:carer/utils/logs.dart';

class NSEntry {
  String? id;
  String? app;
  DateTime date;
  String? device;
  String? direction;
  bool? isReadOnly;

  bool? isValid;
  int sgv;
  String? type;
  int? unfiltered;
  String? units;
  int? utcOffset;
  DateTime createdAt;
  String? identifier;
  int? srvModified;
  int? srvCreated;
  String? subject;

  NSEntry({
    required this.id,
    required this.app,
    required this.date,
    required this.device,
    required this.direction,
    required this.isReadOnly,
    required this.isValid,
    required this.sgv,
    required this.type,
    required this.unfiltered,
    required this.units,
    required this.utcOffset,
    required this.createdAt,
    required this.identifier,
    required this.srvModified,
    required this.srvCreated,
    required this.subject,
  });

  factory NSEntry.fromJson(Map<String, dynamic> json) {
    var guessDate = NSType.getBestGuessDate(json);

    return NSEntry(
      id: json['_id'],
      app: json['app'],
      date: guessDate,
      device: json['device'],
      direction: json['direction'],
      isReadOnly: json['isReadOnly'],
      isValid: json['isValid'],
      sgv: NSType.getInt(json['sgv'], defaultValue: 0)!,
      type: json['type'],
      unfiltered: NSType.getInt(json['unfiltered']),
      units: json['units'],
      utcOffset: NSType.getInt(json['utcOffset']),
      createdAt: guessDate,
      identifier: json['identifier'],
      srvModified: NSType.getInt(json['srvModified']),
      srvCreated: NSType.getInt(json['srvCreated']),
      subject: json['subject'],
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
      final List<dynamic> jsonList = json.decode(jsonStr);
      List<NSEntry> entries = jsonList.map((json) => NSEntry.fromJson(json)).where((e) => e.isValidAndComplete()).toList();
      entries.sort((a, b) => b.date.compareTo(a.date));

      return NSEntries(entries: entries, raw: jsonStr);
    } catch (e, stackTrace) {
      Errors.captureError(e, stackTrace);
      return NSEntries(entries: [], raw: jsonStr);
    }
  }
}
