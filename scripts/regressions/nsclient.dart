import 'dart:convert';
import 'dart:developer';

import 'package:carer/utils/errors.dart';
import 'package:http/http.dart' as http;

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

  factory NSEntries.empty() {
    return NSEntries(entries: []);
  }

  factory NSEntries.fromJson(String jsonStr) {
    try {
      final List<dynamic> jsonList = json.decode(jsonStr);
      List<NSEntry> entries = jsonList.map((json) => NSEntry.fromJson(json)).toList();
      return NSEntries(entries: entries);
    } catch (e, stackTrace) {
      Errors.captureError(e, stackTrace);
      return NSEntries(entries: []);
    }
  }
}

Uri entryEndpoint(nsURL, token, int count) => Uri.parse('$nsURL/api/v1/entries.json?token=$token&count=$count');
Uri treatmentsEndpoint(nsURL, token) => Uri.parse('$nsURL/api/v1/treatments.json?token=$token');

Uri summaryEndpoint(nsURL, token) => Uri.parse('$nsURL/api/v2/summary.json?token=$token');

Uri iobEndpoint(nsURL, token) => Uri.parse('$nsURL/api/v2/properties/iob.json?token=$token');
Uri cobEndpoint(nsURL, token) => Uri.parse('$nsURL/api/v2/properties/cob.json?token=$token');
Uri basalEndpoint(nsURL, token) => Uri.parse('$nsURL/api/v2/properties/basal.json?token=$token');

// Singleton
class NSClient {
  Future<NSEntries> getEntries(String nsURL, String token, int count) async {
    try {
      if (nsURL == "" || token == "") {
        throw Exception("No URL");
      }
      final response = await http.get(entryEndpoint(nsURL, token, count));

      if (response.statusCode != 200) {
        log("NON 200 responce code ${response.statusCode}");
        throw Exception("Bad HTTP");
      }

      return NSEntries.fromJson(response.body);
    } catch (e, stackTrace) {
      Errors.captureError(e, stackTrace);
      return NSEntries.empty();
    }
  }
}
