import 'package:carer/models/sql/constants.dart';
import 'package:carer/nsclient/ns_type.dart';
import 'package:carer/utils/logs.dart';
import 'package:carer/utils/strings.dart';
import 'package:flutter/material.dart';

class NSProfile {
  final String id;
  final String? storeid;
  final String name;
  final int dia;
  final TimeValues carbratio;
  final TimeValues sens;
  final TimeValues basal;
  final TimeValues targetLow;
  final TimeValues targetHigh;
  final String units;
  final String timezone;

  final DateTime date;

  const NSProfile({
    required this.id,
    this.storeid,
    required this.name,
    required this.date,
    required this.dia,
    required this.carbratio,
    required this.sens,
    required this.basal,
    required this.targetLow,
    required this.targetHigh,
    required this.units,
    required this.timezone,
  });

  List<int> expandedCarbratio() => carbratio.expand().map((e) => e.round()).toList();
  List<int> expandedSens() => sens.expand().map((e) => e.round()).toList();
  List<double> expandedBasal() => basal.expand();
  List<int> expandedTargetLow() => targetLow.expand().map((e) => e.round()).toList();
  List<int> expandedTargetHigh() => targetHigh.expand().map((e) => e.round()).toList();

  static (NSProfile?, List<NSProfile>) fromCurrentJson(String jsonString) {
    var (json, err) = tryDecodeJson(jsonString);
    if (err != null) {
      print("Error parsing profile: $err");
      alog("NSError: Failed to decode profile json: $err $jsonString");
      Errors.captureError(err, StackTrace.current);
      return (null, <NSProfile>[]);
    }

    if (json is! Map<String, dynamic>) {
      print("Error parsing profile: JSON is not a Map: $jsonString");
      alog("NSError: Failed to decode profile json:  NOT A MAP $jsonString");
      return (null, <NSProfile>[]);
    }

    var result = json["result"];
    if (result is! List<dynamic> || result.isEmpty) {
      print("Error parsing profile: result is not a List or is empty: $jsonString");
      alog("NSError: Failed to decode profile json: result is not a List or is empty $jsonString");
      return (null, <NSProfile>[]);
    }

    var profileJson = result[0];
    if (profileJson is! Map<String, dynamic>) {
      print("Error parsing profile: profileJson is not a Map: $jsonString");
      alog("NSError: Failed to decode profile json: profileJson is not a Map $jsonString");
      return (null, <NSProfile>[]);
    }

    var store = profileJson["store"];
    if (store is! Map<String, dynamic>) {
      alog("NSError: Failed to decode profile json: store key not found $jsonString");
      return (null, <NSProfile>[]);
    }

    var id = profileJson["identifier"];
    if (id == null) {
      alog("NSError: Failed to decode profile json: id key not found $jsonString");
      return (null, <NSProfile>[]);
    }

    String defaultProfile = profileJson['defaultProfile'].toString();
    if (defaultProfile.isEmpty) {
      alog("NSError: Failed to decode profile json: defaultProfile is empty $jsonString");
      return (null, <NSProfile>[]);
    }

    NSProfile? currentProfile;
    List<NSProfile> otherProfiles = [];

    store.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        var profile = NSProfile.fromJson(key, "${id}_$key", "$id", NSType.getBestGuessDate(profileJson), value);
        if (key == defaultProfile) {
          currentProfile = profile;
        } else {
          otherProfiles.add(profile);
        }
      } else {
        alog("NSError: Failed to decode profile json: store value for key $key is not a Map $jsonString");
      }
    });

    return (currentProfile, otherProfiles);
  }

  factory NSProfile.fromJson(String name, String id, String? storeid, DateTime date, Map<String, dynamic> json) {
    String units = json['units'] ?? "mg/dL";

    var targetLow = TimeValues.fromJson(json['target_low']);
    var targetHigh = TimeValues.fromJson(json['target_high']);

    // The profile comes pre converted to the users units, but it would be easier if they were all just the same mg/dl
    if (units == "mmol") {
      targetLow = targetLow.map((e) {
        e.value = e.value * MGtoMMOL;
        return e;
      });
      targetHigh = targetHigh.map((e) {
        e.value = e.value * MGtoMMOL;
        return e;
      });
    }

    return NSProfile(
      id: id,
      storeid: storeid,
      name: name,
      date: date,
      dia: NSType.getInt(json['dia'], defaultValue: 5)!,
      carbratio: TimeValues.fromJson(json['carbratio']),
      sens: TimeValues.fromJson(json['sens']),
      basal: TimeValues.fromJson(json['basal']),
      targetLow: targetLow,
      targetHigh: targetHigh,
      units: units,
      timezone: json['timezone'] ?? "Pacific/Auckland",
    );
  }
}

class TimeValue {
  TimeOfDay time;
  double value;

  TimeValue({
    required this.time,
    required this.value,
  });

  factory TimeValue.fromJson(Map<String, dynamic> json) {
    final dateTime = DateTime.parse("1970-01-01T${json['time']}");
    final timeOfDay = TimeOfDay.fromDateTime(dateTime);

    var jsonValue = json['value'];
    double value = 0;
    if (jsonValue is String) {
      value = double.tryParse(jsonValue) ?? 0;
    }
    if (jsonValue is num) {
      value = jsonValue.toDouble();
    }

    return TimeValue(
      time: timeOfDay,
      value: value,
    );
  }
}

class TimeValues {
  final List<TimeValue> values;

  const TimeValues({
    required this.values,
  });

  TimeValues map(TimeValue Function(TimeValue) f) {
    List<TimeValue> newValues = values.map(f).toList();
    return TimeValues(values: newValues);
  }

  factory TimeValues.fromJson(List<dynamic>? json) {
    if (json == null) {
      return const TimeValues(values: []);
    }

    List<TimeValue> values = json.map((valueJson) => TimeValue.fromJson(valueJson)).toList();

    // Sort this to make the TimeValues chronologically ordered
    return TimeValues(values: values);
  }

  List<double> expand() {
    if (values.isEmpty) {
      return [];
    }
    List<double> expanded = [];
    var vi = 0;

    for (var i = 0; i < 24; i++) {
      var current = values[vi];

      if (values.length == vi + 1) {
        // end of values
        expanded.add(current.value);
        continue;
      }
      var next = values[vi + 1];
      if (next.time.hour == i) {
        expanded.add(next.value);
        vi++;
        continue;
      }

      expanded.add(current.value);
    }
    return expanded;
  }
}
