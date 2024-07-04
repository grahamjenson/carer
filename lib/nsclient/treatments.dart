import 'dart:convert';

import 'package:carer/utils/errors.dart';

class NSTreatment {
  String id;
  String app;
  int? carbs;
  DateTime date; // Now, date is a DateTime object
  String eventType;
  bool isReadOnly;
  bool isValid;
  int utcOffset;
  DateTime createdAt;
  String identifier;
  int srvModified;
  int srvCreated;
  String subject;
  double? insulin;

  NSTreatment({
    required this.id,
    required this.app,
    required this.carbs,
    required this.date,
    required this.eventType,
    required this.isReadOnly,
    required this.isValid,
    required this.utcOffset,
    required this.createdAt,
    required this.identifier,
    required this.srvModified,
    required this.srvCreated,
    required this.subject,
    required this.insulin,
  });

  factory NSTreatment.fromJson(Map<String, dynamic> json) {
    return NSTreatment(
      id: json['_id'],
      app: json['app'],
      carbs: json['carbs'],
      date: DateTime.fromMillisecondsSinceEpoch(json['date']),
      eventType: json['eventType'],
      isReadOnly: json['isReadOnly'],
      isValid: json['isValid'],
      utcOffset: json['utcOffset'],
      createdAt: DateTime.parse(json['created_at']),
      identifier: json['identifier'],
      srvModified: json['srvModified'],
      srvCreated: json['srvCreated'],
      subject: json['subject'],
      insulin: json['insulin']?.toDouble(),
    );
  }
}

class NSTreatments {
  List<NSTreatment> treatments;

  NSTreatments({required this.treatments});

  factory NSTreatments.empty() {
    return NSTreatments(treatments: []);
  }

  factory NSTreatments.fromJson(String jsonString) {
    try {
      final List<dynamic> jsonList = json.decode(jsonString);
      List<NSTreatment> treatmentsList = jsonList.map((json) => NSTreatment.fromJson(json)).toList();

      return NSTreatments(treatments: treatmentsList);
    } catch (e, stackTrace) {
      Errors.captureError(e, stackTrace);
      return NSTreatments(treatments: []);
    }
  }
}
