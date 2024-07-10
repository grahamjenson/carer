import 'dart:convert';

import 'package:carer/utils/logs.dart';

class NSRawTreatment {
  String id;
  String? app;
  int? carbs;
  DateTime date; // Now, date is a DateTime object
  String eventType;
  bool? isReadOnly;
  bool? isValid;
  int utcOffset;
  DateTime createdAt;
  String? identifier;
  int? srvModified;
  int? srvCreated;
  String? subject;
  double? insulin;

  int? duration;
  int? durationInMilliseconds;
  double? absolute;

  double? targetBottom;
  double? targetTop;
  String? reason;

  Map<String, dynamic> rawJson;

  NSRawTreatment({
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
    required this.duration,
    required this.durationInMilliseconds,
    required this.absolute,
    required this.targetBottom,
    required this.targetTop,
    required this.reason,
    required this.rawJson,
  });

  factory NSRawTreatment.fromJson(Map<String, dynamic> json) {
    if (json["date"] == null) {
      // nightguard carportal aparently doesnt add a date!!!
      // e.g.
      // "_id": "6682e197db18d84d3b13b4de",
      // "eventType": "Carb Correction",
      // "carbs": 1,
      // "duration": 0,
      // "enteredBy": "nightguard",
      // "created_at": "2024-07-01T17:04:23.645Z",
      // "utcOffset": 0,
      // "insulin": null

      var date = DateTime.parse(json["created_at"]);
      json["date"] = date.millisecondsSinceEpoch;
    }
    return NSRawTreatment(
      id: json['_id'],
      app: json['app'],
      carbs: json['carbs'],
      date: DateTime.fromMillisecondsSinceEpoch(json['date']),
      eventType: json['eventType'],
      utcOffset: json['utcOffset'],
      isReadOnly: json['isReadOnly'],
      isValid: json['isValid'],
      createdAt: DateTime.parse(json['created_at']),
      identifier: json['identifier'],
      srvModified: json['srvModified'],
      srvCreated: json['srvCreated'],
      subject: json['subject'],
      insulin: json['insulin']?.toDouble(),
      absolute: json['absolute']?.toDouble(),
      duration: json['duration'],
      durationInMilliseconds: json['durationInMilliseconds'],
      targetBottom: json['targetBottom']?.toDouble(),
      targetTop: json['targetTop']?.toDouble(),
      reason: json['reason'],
      rawJson: json,
    );
  }

  List<NSTreatment> toTreatments() {
    List<NSTreatment> treatments = [];
    switch (eventType) {
      case "Temp Basal":
        if (absolute != null) {
          treatments.add(NSTreatmentTempBasal(id: id, absolute: absolute ?? 0, date: date, durationInMilliseconds: durationInMilliseconds ?? 0));
        }
        break;
      case "Temporary Target":
        if (targetBottom != null && targetTop != null) {
          treatments.add(NSTemporaryTarget(
              id: id, targetBottom: targetBottom!, targetTop: targetTop!, date: date, durationInMilliseconds: durationInMilliseconds ?? 0));
        }
        break;
      case "Meal Bolus" || "Correction Bolus":
        if (carbs != null) {
          treatments.add(NSTreatmentCarbs(id: id, carbs: carbs!, date: date));
        }
        if (insulin != null) {
          treatments.add(NSTreatmentInsulin(id: id, insulin: insulin!, date: date));
        }
        break;
      case "Carb Correction":
        assert(insulin == null);
        if (carbs != null) {
          treatments.add(NSTreatmentCarbs(id: id, carbs: carbs!, date: date));
        }
        break;
      case "Profile Switch":
        // TODO;
        break;
      case "Note":
        // TODO;
        break;
    }

    if (treatments.isEmpty) {
      alog("No treatments found in $rawJson");
    }
    return treatments;
  }
}

abstract class NSTreatment {}

class NSTreatmentCarbs extends NSTreatment {
  String id;
  int carbs;
  DateTime date;
  NSTreatmentCarbs({required this.id, required this.carbs, required this.date});

  @override
  String toString() {
    return "Carbs: $carbs at $date";
  }
}

class NSTreatmentInsulin extends NSTreatment {
  String id;
  double insulin;
  DateTime date;
  NSTreatmentInsulin({required this.id, required this.insulin, required this.date});

  @override
  String toString() {
    return "Insulin: $insulin at $date";
  }
}

class NSTreatmentTempBasal extends NSTreatment {
  String id;
  double absolute;
  DateTime date;
  int durationInMilliseconds;
  NSTreatmentTempBasal({required this.id, required this.absolute, required this.date, required this.durationInMilliseconds});

  @override
  String toString() {
    return "TempBasal: $absolute for $durationInMilliseconds at $date";
  }
}

class NSTemporaryTarget extends NSTreatment {
  String id;
  double targetBottom;
  double targetTop;
  int durationInMilliseconds;
  DateTime date;
  NSTemporaryTarget(
      {required this.id, required this.targetBottom, required this.targetTop, required this.date, required this.durationInMilliseconds});

  @override
  String toString() {
    return "TempTarget: $targetBottom - $targetTop at $date";
  }
}

class NSTreatments {
  List<NSTreatment> treatments;
  String raw;
  NSTreatments({required this.treatments, required this.raw});

  factory NSTreatments.empty() {
    return NSTreatments(treatments: [], raw: "");
  }

  factory NSTreatments.fromJson(String jsonString) {
    try {
      final List<dynamic> jsonList = json.decode(jsonString);
      List<NSRawTreatment> rawTreatments = jsonList.map((json) => NSRawTreatment.fromJson(json)).toList();

      List<NSTreatment> treatments = [];
      for (var rt in rawTreatments) {
        treatments.addAll(rt.toTreatments());
      }
      return NSTreatments(treatments: treatments, raw: jsonString);
    } catch (e, stackTrace) {
      Errors.captureError(e, stackTrace);
      return NSTreatments(treatments: [], raw: jsonString);
    }
  }

  List<NSTreatmentCarbs> get carbs {
    return treatments.whereType<NSTreatmentCarbs>().toList();
  }

  List<NSTreatmentInsulin> get boluses {
    return treatments.whereType<NSTreatmentInsulin>().toList();
  }

  List<NSTreatmentTempBasal> get tempBasals {
    return treatments.whereType<NSTreatmentTempBasal>().toList();
  }

  List<NSTemporaryTarget> get tempTargets {
    return treatments.whereType<NSTemporaryTarget>().toList();
  }
}
