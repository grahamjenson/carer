import 'dart:convert';

import 'package:carer/models/sql/constants.dart';
import 'package:carer/nsclient/ns_type.dart';
import 'package:carer/nsclient/shared.dart';
import 'package:carer/utils/logs.dart';

class NSRawTreatment {
  String id;
  String? app;
  int? carbs;
  DateTime date; // Now, date is a DateTime object
  String eventType;
  String? type;
  bool? isReadOnly;
  bool? isValid;
  int? utcOffset;
  DateTime createdAt;
  String? identifier;
  int? srvModified;
  int? srvCreated;
  String? subject;
  double? insulin;

  double? duration;
  int? durationInMilliseconds;
  double? absolute;
  double? rate;

  double? targetBottom;
  double? targetTop;
  String? reason;
  String? units;

  // Profile Switch Specifics
  int? originalDuration;
  String? originalProfileName;
  String? profile;
  String? profileJson;
  int? percentage;
  int? originalPercentage;

  Map<String, dynamic> rawJson;

  NSRawTreatment({
    required this.id,
    required this.carbs,
    required this.date,
    required this.type,
    required this.eventType,
    required this.utcOffset,
    required this.createdAt,
    required this.identifier,
    required this.insulin,
    required this.duration,
    required this.durationInMilliseconds,
    required this.absolute,
    required this.rate,
    required this.targetBottom,
    required this.targetTop,
    required this.reason,
    required this.units,
    required this.originalDuration,
    required this.originalProfileName,
    required this.profile,
    required this.profileJson,
    required this.percentage,
    required this.originalPercentage,
    required this.rawJson,
  });

  factory NSRawTreatment.fromJson(Map<String, dynamic> json) {
    var guessDate = NSType.getBestGuessDate(json);

    return NSRawTreatment(
      id: json['identifier'] ?? "",
      carbs: NSType.getInt(json['carbs']),
      date: guessDate,
      type: json['type'],
      eventType: json['eventType'] ?? "",
      utcOffset: NSType.getInt(json['utcOffset']),
      createdAt: guessDate,
      identifier: json['identifier'],
      insulin: NSType.getDouble(json['insulin']),
      absolute: NSType.getDouble(json['absolute']),
      rate: NSType.getDouble(json['rate']),
      duration: NSType.getDouble(json['duration']),
      durationInMilliseconds: NSType.getInt(json['durationInMilliseconds']),
      targetBottom: NSType.getDouble(json['targetBottom']),
      targetTop: NSType.getDouble(json['targetTop']),
      reason: json['reason'],
      units: json['units'],
      originalDuration: NSType.getInt(json['originalDuration']),
      originalProfileName: json['originalProfileName'],
      profile: json['profile'],
      percentage: NSType.getInt(json['percentage']),
      originalPercentage: NSType.getInt(json['originalPercentage']),
      profileJson: json['profileJson'],
      rawJson: json,
    );
  }

  bool isValidAndComplete() {
    if (id.isEmpty || eventType.isEmpty) {
      return false;
    }

    return true;
  }

  int guessDurationInMilliseconds() {
    if (durationInMilliseconds != null) {
      return durationInMilliseconds!;
    }
    if (duration != null) {
      return (duration! * 60 * 1000).round();
    }
    return 0;
  }

  List<NSTreatment> toTreatments() {
    List<NSTreatment> treatments = [];
    String raw = json.encode(rawJson);
    switch (eventType) {
      case "Temp Basal":
        if (absolute != null || rate != null) {
          double r = absolute ?? rate ?? 0;
          treatments.add(NSTreatmentTempBasal(
            id: id,
            absolute: r,
            date: date,
            durationInMilliseconds: guessDurationInMilliseconds(),
            raw: raw,
          ));
        }
        break;
      case "Temporary Target":
        if (targetBottom != null && targetTop != null) {
          treatments.add(NSTemporaryTarget(
            id: id,
            targetBottom: targetBottom!,
            targetTop: targetTop!,
            date: date,
            durationInMilliseconds: guessDurationInMilliseconds(),
            units: units,
            raw: raw,
          ));
        }
        break;
      case "Meal Bolus" || "Correction Bolus":
        if (carbs != null) {
          treatments.add(NSTreatmentCarbs(id: id, carbs: carbs!, date: date, raw: raw));
        }
        if (insulin != null) {
          var ttype = eventType == "Meal Bolus" ? NSTreatmentInsulinType.meal : NSTreatmentInsulinType.correction;
          if (type == "SMB") {
            ttype = NSTreatmentInsulinType.smb;
          }
          treatments.add(NSTreatmentInsulin(id: id, insulin: insulin!, date: date, type: ttype, raw: raw));
        }
        break;
      case "Carb Correction":
        assert(insulin == null);
        if (carbs != null) {
          treatments.add(NSTreatmentCarbs(id: id, carbs: carbs!, date: date, raw: raw));
        }
        break;
      case "Profile Switch":
        if (originalDuration != null && originalProfileName != null && percentage != null && profileJson != null) {
          var profileVariables = json.decode(profileJson!);
          var profileModel = NSProfile.fromJson(originalProfileName!, id, null, date, profileVariables);

          treatments.add(NSProfileSwitch(
            durationInMilliseconds: originalDuration!,
            percentage: percentage!,
            profile: profileModel,
            raw: raw,
          ));
        }
        break;
      case "Note":
        // After changing a profile in Carer, AAPS puts a full Note with calculated profileJSON which is useful to use here
        if (originalDuration != null && originalProfileName != null && originalPercentage != null && profileJson != null) {
          var profileVariables = json.decode(profileJson!);
          var profileModel = NSProfile.fromJson(originalProfileName!, id, null, date, profileVariables);
          // If the Note has these fields it is actually a profile switch BACK to the original profile
          treatments.add(NSProfileSwitch(
            durationInMilliseconds: originalDuration!,
            percentage: originalPercentage!,
            profile: profileModel,
            raw: json.encode(rawJson),
          ));
        }
        break;
      case "Sensor Change":
        treatments.add(NSSensorChange(id: id, date: date, raw: raw));
        break;
      case "Insulin Change":
        treatments.add(NSInsulinChange(id: id, date: date, raw: raw));
        break;
    }

    if (treatments.isEmpty) {
      alog("No treatments found in $id $eventType");
    }
    return treatments;
  }
}

abstract class NSTreatment {}

class NSTreatmentCarbs extends NSTreatment {
  String id;
  int carbs;
  DateTime date;
  String raw;
  NSTreatmentCarbs({required this.id, required this.carbs, required this.date, required this.raw});

  @override
  String toString() {
    return "Carbs: $carbs at $date";
  }
}

enum NSTreatmentInsulinType { meal, correction, smb }

class NSTreatmentInsulin extends NSTreatment {
  String id;
  double insulin;
  DateTime date;
  NSTreatmentInsulinType type;
  String raw;

  NSTreatmentInsulin({
    required this.id,
    required this.insulin,
    required this.date,
    required this.type,
    required this.raw,
  });

  @override
  String toString() {
    return "Insulin(${type.name}): $insulin at $date";
  }
}

class NSTreatmentTempBasal extends NSTreatment {
  String id;
  double absolute;
  DateTime date;
  int durationInMilliseconds;
  String raw;
  NSTreatmentTempBasal({
    required this.id,
    required this.absolute,
    required this.date,
    required this.durationInMilliseconds,
    required this.raw,
  });

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
  String? units;
  String raw;

  NSTemporaryTarget(
      {required this.id,
      required this.targetBottom,
      required this.targetTop,
      required this.date,
      required this.durationInMilliseconds,
      required this.units,
      required this.raw}) {
    if (units != null && units == "mmol") {
      // Convert to mg/dL
      targetBottom = targetBottom * MGtoMMOL;
      targetTop = targetTop * MGtoMMOL;
    }
  }

  @override
  String toString() {
    return "TempTarget: $targetBottom - $targetTop at $date";
  }
}

class NSProfileSwitch extends NSTreatment {
  int durationInMilliseconds;
  int percentage;
  String raw;

  NSProfile profile;

  NSProfileSwitch({
    required this.durationInMilliseconds,
    required this.percentage,
    required this.profile,
    required this.raw,
  });

  @override
  String toString() {
    return "ProfileSwitch: $name($percentage) at $date for ${durationInMilliseconds ~/ 60000} mins";
  }

  get name => profile.name;
  get id => profile.id;
  get date => profile.date;
}

class NSSensorChange extends NSTreatment {
  String id;
  DateTime date;
  String raw;
  NSSensorChange({required this.id, required this.date, required this.raw});

  @override
  String toString() {
    return "SensorChange: $id at $date";
  }
}

class NSInsulinChange extends NSTreatment {
  String id;
  DateTime date;
  String raw;
  NSInsulinChange({required this.id, required this.date, required this.raw});

  @override
  String toString() {
    return "InsulinChange: $id at $date";
  }
}

class NSTreatments {
  List<NSTreatment> treatments;
  String raw;
  // From a history: the identifiers of the documents deleted, the srvModified of the last change, and how many
  // documents the page had, to know whether there are more
  List<String> deletedIds;
  int? lastSrvModified;
  int count;
  NSTreatments({required this.treatments, required this.raw, this.deletedIds = const [], this.lastSrvModified, this.count = 0});

  int get length => treatments.length;
  NSTreatment operator [](int index) => treatments[index];

  factory NSTreatments.empty() {
    return NSTreatments(treatments: [], raw: "");
  }

  factory NSTreatments.fromJson(String jsonStr) {
    try {
      final Map<String, dynamic> jsonObject = json.decode(jsonStr);
      final List<dynamic> jsonList = jsonObject['result'] ?? [];
      var (deletedIds, lastSrvModified) = NSType.deletedAndLastModified(jsonList);
      List<NSRawTreatment> rawTreatments =
          jsonList.where((json) => json['isValid'] != false).map((json) => NSRawTreatment.fromJson(json)).where((e) => e.isValidAndComplete()).toList();

      rawTreatments.sort((a, b) => b.date.compareTo(a.date));

      List<NSTreatment> treatments = [];
      for (var rt in rawTreatments) {
        treatments.addAll(rt.toTreatments());
      }
      return NSTreatments(treatments: treatments, raw: jsonStr, deletedIds: deletedIds, lastSrvModified: lastSrvModified, count: jsonList.length);
    } catch (e, stackTrace) {
      Errors.captureError(e, stackTrace);
      return NSTreatments(treatments: [], raw: jsonStr);
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

  List<NSProfileSwitch> get profileSwitches {
    return treatments.whereType<NSProfileSwitch>().toList();
  }

  List<NSSensorChange> get sensorChanges {
    return treatments.whereType<NSSensorChange>().toList();
  }

  List<NSInsulinChange> get insulinChanges {
    return treatments.whereType<NSInsulinChange>().toList();
  }
}
