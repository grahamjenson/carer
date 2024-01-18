import 'dart:convert';

class Treatment {
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

  Treatment({
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

  factory Treatment.fromJson(Map<String, dynamic> json) {
    return Treatment(
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

class Treatments {
  List<Treatment> treatments;

  Treatments({required this.treatments});

  factory Treatments.fromJson(String jsonString) {
    try {
      final List<dynamic> jsonList = json.decode(jsonString);
      List<Treatment> treatmentsList =
          jsonList.map((json) => Treatment.fromJson(json)).toList();

      return Treatments(treatments: treatmentsList);
    } catch (e) {
      print("Error parsing treatments: $e");
      return Treatments(treatments: []);
    }
  }
}
