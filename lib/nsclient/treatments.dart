import 'dart:convert';

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
    required this.app,
    required this.carbs,
    required this.date,
    required this.type,
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
    required this.rate,
    required this.targetBottom,
    required this.targetTop,
    required this.reason,
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
      id: json['_id'] ?? "",
      app: json['app'],
      carbs: json['carbs'],
      date: guessDate,
      type: json['type'],
      eventType: json['eventType'] ?? "",
      utcOffset: NSType.getInt(json['utcOffset']),
      isReadOnly: json['isReadOnly'],
      isValid: json['isValid'],
      createdAt: guessDate,
      identifier: json['identifier'],
      srvModified: json['srvModified'],
      srvCreated: json['srvCreated'],
      subject: json['subject'],
      insulin: NSType.getDouble(json['insulin']),
      absolute: NSType.getDouble(json['absolute']),
      rate: NSType.getDouble(json['rate']),
      duration: NSType.getDouble(json['duration']),
      durationInMilliseconds: NSType.getInt(json['durationInMilliseconds']),
      targetBottom: NSType.getDouble(json['targetBottom']),
      targetTop: NSType.getDouble(json['targetTop']),
      reason: json['reason'],
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

    switch (eventType) {
      case "Temp Basal":
        if (absolute != null || rate != null) {
          double r = absolute ?? rate ?? 0;
          treatments.add(NSTreatmentTempBasal(
            id: id,
            absolute: r,
            date: date,
            durationInMilliseconds: guessDurationInMilliseconds(),
          ));
        }
        break;
      case "Temporary Target":
        if (targetBottom != null && targetTop != null) {
          treatments.add(NSTemporaryTarget(
              id: id, targetBottom: targetBottom!, targetTop: targetTop!, date: date, durationInMilliseconds: guessDurationInMilliseconds()));
        }
        break;
      case "Meal Bolus" || "Correction Bolus":
        if (carbs != null) {
          treatments.add(NSTreatmentCarbs(id: id, carbs: carbs!, date: date));
        }
        if (insulin != null) {
          var ttype = eventType == "Meal Bolus" ? NSTreatmentInsulinType.meal : NSTreatmentInsulinType.correction;
          if (type == "SMB") {
            ttype = NSTreatmentInsulinType.smb;
          }
          treatments.add(NSTreatmentInsulin(id: id, insulin: insulin!, date: date, type: ttype));
        }
        break;
      case "Carb Correction":
        assert(insulin == null);
        if (carbs != null) {
          treatments.add(NSTreatmentCarbs(id: id, carbs: carbs!, date: date));
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
          ));
        }
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
  NSTreatmentCarbs({required this.id, required this.carbs, required this.date});

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

  NSTreatmentInsulin({required this.id, required this.insulin, required this.date, required this.type});

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

//
// {
//   "_id": "6690a3535de9b827ea1daf8d",
//   "app": "AAPS",
//   "date": 1720755027430,
//   "eventType": "Note",
//   "isReadOnly": false,
//   "isValid": true,
//   "notes": "SamDash-2023-11SMB",
//   "originalCustomizedName": "SamDash-2023-11SMB",
//   "originalDuration": 0,
//   "originalEnd": 1720695980000,
//   "originalPercentage": 100,
//   "originalProfileName": "SamDash-2023-11SMB",
//   "originalTimeshift": 0,
//   "profileJson": "{\"units\":\"mmol\",\"dia\":6,\"timezone\":\"Pacific\\/Kwajalein\",\"sens\":[{\"time\":\"00:00\",\"timeAsSeconds\":0,\"value\":20},{\"time\":\"06:00\",\"timeAsSeconds\":21600,\"value\":7},{\"time\":\"09:00\",\"timeAsSeconds\":32400,\"value\":11.5},{\"time\":\"12:00\",\"timeAsSeconds\":43200,\"value\":12},{\"time\":\"22:00\",\"timeAsSeconds\":79200,\"value\":15}],\"carbratio\":[{\"time\":\"00:00\",\"timeAsSeconds\":0,\"value\":20},{\"time\":\"05:00\",\"timeAsSeconds\":18000,\"value\":8},{\"time\":\"09:00\",\"timeAsSeconds\":32400,\"value\":11},{\"time\":\"14:00\",\"timeAsSeconds\":50400,\"value\":13},{\"time\":\"19:00\",\"timeAsSeconds\":68400,\"value\":14}],\"basal\":[{\"time\":\"00:00\",\"timeAsSeconds\":0,\"value\":0.2},{\"time\":\"01:00\",\"timeAsSeconds\":3600,\"value\":0.25},{\"time\":\"02:00\",\"timeAsSeconds\":7200,\"value\":0.23},{\"time\":\"03:00\",\"timeAsSeconds\":10800,\"value\":0.25},{\"time\":\"05:00\",\"timeAsSeconds\":18000,\"value\":0.35},{\"time\":\"06:00\",\"timeAsSeconds\":21600,\"value\":0.65},{\"time\":\"09:00\",\"timeAsSeconds\":32400,\"value\":0.55},{\"time\":\"10:00\",\"timeAsSeconds\":36000,\"value\":0.3},{\"time\":\"11:00\",\"timeAsSeconds\":39600,\"value\":0.25},{\"time\":\"15:00\",\"timeAsSeconds\":54000,\"value\":0.3},{\"time\":\"16:00\",\"timeAsSeconds\":57600,\"value\":0.25},{\"time\":\"18:00\",\"timeAsSeconds\":64800,\"value\":0.4},{\"time\":\"20:00\",\"timeAsSeconds\":72000,\"value\":0.3},{\"time\":\"21:00\",\"timeAsSeconds\":75600,\"value\":0.25},{\"time\":\"22:00\",\"timeAsSeconds\":79200,\"value\":0.2}],\"target_low\":[{\"time\":\"00:00\",\"timeAsSeconds\":0,\"value\":5.5},{\"time\":\"05:00\",\"timeAsSeconds\":18000,\"value\":5.5},{\"time\":\"09:00\",\"timeAsSeconds\":32400,\"value\":6},{\"time\":\"14:00\",\"timeAsSeconds\":50400,\"value\":5.5},{\"time\":\"23:00\",\"timeAsSeconds\":82800,\"value\":6}],\"target_high\":[{\"time\":\"00:00\",\"timeAsSeconds\":0,\"value\":7},{\"time\":\"05:00\",\"timeAsSeconds\":18000,\"value\":6},{\"time\":\"09:00\",\"timeAsSeconds\":32400,\"value\":7},{\"time\":\"14:00\",\"timeAsSeconds\":50400,\"value\":6.5},{\"time\":\"23:00\",\"timeAsSeconds\":82800,\"value\":6.5}]}",
//   "utcOffset": 720,
//   "created_at": "2024-07-12T03:30:27.430Z",
//   "identifier": "6b37517b-0cd6-58fd-ba0e-be08097b2b3b",
//   "srvModified": 1720755027798,
//   "srvCreated": 1720755027798,
//   "subject": "phone",
//   "carbs": null,
//   "insulin": null
// },

// {
//   "_id": "6690a3585de9b81f2d1daf8e",
//   "app": "AAPS",
//   "date": 1720755031772,
//   "duration": 54000000000,
//   "eventType": "Profile Switch",
//   "isReadOnly": false,
//   "isValid": true,
//   "originalDuration": 900000,
//   "originalProfileName": "SamDash-2023-11SMB",
//   "percentage": 120,
//   "profile": "SamDash-2023-11SMB(120%)",
//   "profileJson": "{\"units\":\"mmol\",\"dia\":6,\"timezone\":\"Pacific\\/Kwajalein\",\"sens\":[{\"time\":\"00:00\",\"timeAsSeconds\":0,\"value\":20},{\"time\":\"03:00\",\"timeAsSeconds\":10800,\"value\":20},{\"time\":\"06:00\",\"timeAsSeconds\":21600,\"value\":7},{\"time\":\"09:00\",\"timeAsSeconds\":32400,\"value\":11.5},{\"time\":\"12:00\",\"timeAsSeconds\":43200,\"value\":12},{\"time\":\"22:00\",\"timeAsSeconds\":79200,\"value\":15}],\"carbratio\":[{\"time\":\"00:00\",\"timeAsSeconds\":0,\"value\":20},{\"time\":\"02:00\",\"timeAsSeconds\":7200,\"value\":20},{\"time\":\"05:00\",\"timeAsSeconds\":18000,\"value\":8},{\"time\":\"09:00\",\"timeAsSeconds\":32400,\"value\":11},{\"time\":\"14:00\",\"timeAsSeconds\":50400,\"value\":13},{\"time\":\"19:00\",\"timeAsSeconds\":68400,\"value\":14}],\"basal\":[{\"time\":\"00:00\",\"timeAsSeconds\":0,\"value\":0.2},{\"time\":\"01:00\",\"timeAsSeconds\":3600,\"value\":0.25},{\"time\":\"02:00\",\"timeAsSeconds\":7200,\"value\":0.23},{\"time\":\"03:00\",\"timeAsSeconds\":10800,\"value\":0.25},{\"time\":\"04:00\",\"timeAsSeconds\":14400,\"value\":0.25},{\"time\":\"05:00\",\"timeAsSeconds\":18000,\"value\":0.35},{\"time\":\"06:00\",\"timeAsSeconds\":21600,\"value\":0.65},{\"time\":\"07:00\",\"timeAsSeconds\":25200,\"value\":0.65},{\"time\":\"08:00\",\"timeAsSeconds\":28800,\"value\":0.65},{\"time\":\"09:00\",\"timeAsSeconds\":32400,\"value\":0.55},{\"time\":\"10:00\",\"timeAsSeconds\":36000,\"value\":0.3},{\"time\":\"11:00\",\"timeAsSeconds\":39600,\"value\":0.25},{\"time\":\"12:00\",\"timeAsSeconds\":43200,\"value\":0.25},{\"time\":\"13:00\",\"timeAsSeconds\":46800,\"value\":0.25},{\"time\":\"14:00\",\"timeAsSeconds\":50400,\"value\":0.25},{\"time\":\"15:00\",\"timeAsSeconds\":54000,\"value\":0.3},{\"time\":\"16:00\",\"timeAsSeconds\":57600,\"value\":0.25},{\"time\":\"17:00\",\"timeAsSeconds\":61200,\"value\":0.25},{\"time\":\"18:00\",\"timeAsSeconds\":64800,\"value\":0.4},{\"time\":\"19:00\",\"timeAsSeconds\":68400,\"value\":0.4},{\"time\":\"20:00\",\"timeAsSeconds\":72000,\"value\":0.3},{\"time\":\"21:00\",\"timeAsSeconds\":75600,\"value\":0.25},{\"time\":\"22:00\",\"timeAsSeconds\":79200,\"value\":0.2},{\"time\":\"23:00\",\"timeAsSeconds\":82800,\"value\":0.2}],\"target_low\":[{\"time\":\"00:00\",\"timeAsSeconds\":0,\"value\":5.5},{\"time\":\"05:00\",\"timeAsSeconds\":18000,\"value\":5.5},{\"time\":\"09:00\",\"timeAsSeconds\":32400,\"value\":6},{\"time\":\"14:00\",\"timeAsSeconds\":50400,\"value\":5.5},{\"time\":\"23:00\",\"timeAsSeconds\":82800,\"value\":6}],\"target_high\":[{\"time\":\"00:00\",\"timeAsSeconds\":0,\"value\":7},{\"time\":\"05:00\",\"timeAsSeconds\":18000,\"value\":6},{\"time\":\"09:00\",\"timeAsSeconds\":32400,\"value\":7},{\"time\":\"14:00\",\"timeAsSeconds\":50400,\"value\":6.5},{\"time\":\"23:00\",\"timeAsSeconds\":82800,\"value\":6.5}]}",
//   "timeshift": 0,
//   "utcOffset": 720,
//   "created_at": "2024-07-12T03:30:31.772Z",
//   "identifier": "28cf6118-2346-5e0f-ab01-87ba52b22ad1",
//   "srvModified": 1720755032137,
//   "srvCreated": 1720755032137,
//   "subject": "phone",
//   "carbs": null,
//   "insulin": null
// },

class NSProfileSwitch extends NSTreatment {
  int durationInMilliseconds;
  int percentage;

  NSProfile profile;

  NSProfileSwitch({
    required this.durationInMilliseconds,
    required this.percentage,
    required this.profile,
  });

  @override
  String toString() {
    return "ProfileSwitch: $name($percentage) at $date for ${durationInMilliseconds ~/ 60000} mins";
  }

  get name => profile.name;
  get id => profile.id;
  get date => profile.date;
}

class NSTreatments {
  List<NSTreatment> treatments;
  String raw;
  NSTreatments({required this.treatments, required this.raw});

  int get length => treatments.length;
  NSTreatment operator [](int index) => treatments[index];

  factory NSTreatments.empty() {
    return NSTreatments(treatments: [], raw: "");
  }

  factory NSTreatments.fromJson(String jsonString) {
    try {
      final List<dynamic> jsonList = json.decode(jsonString);
      List<NSRawTreatment> rawTreatments = jsonList.map((json) => NSRawTreatment.fromJson(json)).where((e) => e.isValidAndComplete()).toList();

      rawTreatments.sort((a, b) => b.date.compareTo(a.date));

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

  List<NSProfileSwitch> get profileSwitchs {
    return treatments.whereType<NSProfileSwitch>().toList();
  }
}
