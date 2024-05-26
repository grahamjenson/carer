import 'dart:convert';

import 'package:carer/utils/errors.dart';

class NSEntry {
  String id;
  String app;
  DateTime date;
  String device;
  String direction;
  bool isReadOnly;
  bool isValid;
  int? sgv;
  String type;
  int unfiltered;
  String units;
  int utcOffset;
  DateTime createdAt;
  String identifier;
  int srvModified;
  int srvCreated;
  String subject;

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
    return NSEntry(
      id: json['_id'],
      app: json['app'],
      date: DateTime.fromMillisecondsSinceEpoch(json['date']),
      device: json['device'],
      direction: json['direction'],
      isReadOnly: json['isReadOnly'],
      isValid: json['isValid'],
      sgv: json['sgv'],
      type: json['type'],
      unfiltered: json['unfiltered'],
      units: json['units'],
      utcOffset: json['utcOffset'],
      createdAt: DateTime.parse(json['created_at']),
      identifier: json['identifier'],
      srvModified: json['srvModified'],
      srvCreated: json['srvCreated'],
      subject: json['subject'],
    );
  }
}

class NSEntries {
  List<NSEntry> entries;

  bool isEmpty() => entries.isEmpty;
  NSEntry? firstOrNull() => entries.firstOrNull;

  NSEntries({
    required this.entries,
  });

  factory NSEntries.fromJson(String jsonStr) {
    try {
      final List<dynamic> jsonList = json.decode(jsonStr);
      List<NSEntry> entries =
          jsonList.map((json) => NSEntry.fromJson(json)).toList();
      return NSEntries(entries: entries);
    } catch (e, stackTrace) {
      Errors.captureException(e, stackTrace: stackTrace);
      return NSEntries(entries: []);
    }
  }

  // Add any additional methods or properties as needed
}
