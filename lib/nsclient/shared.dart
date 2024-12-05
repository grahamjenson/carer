import 'dart:convert';

import 'package:carer/models/sql/constants.dart';
import 'package:carer/utils/logs.dart';
import 'package:flutter/material.dart';

class NSProfile {
  final String id;
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

  final String? raw;

  const NSProfile({
    this.raw,
    required this.id,
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

  static NSProfile? fromCurrentJson(String jsonString) {
    try {
      var json = jsonDecode(jsonString);
      Map<String, dynamic> profileStore = json["store"];
      var profileName = profileStore.keys.firstOrNull;
      Map<String, dynamic> profileValues = profileStore[profileName];
      return NSProfile.fromJson(
        profileName!,
        json["_id"]!,
        DateTime.fromMillisecondsSinceEpoch(json['date'] ?? 0),
        profileValues,
        raw: jsonString,
      );
    } catch (e, stackTrace) {
      Errors.captureError(e, stackTrace);
      return null;
    }
  }

  factory NSProfile.fromJson(String name, String id, DateTime date, Map<String, dynamic> json, {String raw = ""}) {
    var units = json['units'];

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
      raw: raw,
      id: id,
      name: name,
      date: date,
      dia: json['dia'],
      carbratio: TimeValues.fromJson(json['carbratio']),
      sens: TimeValues.fromJson(json['sens']),
      basal: TimeValues.fromJson(json['basal']),
      targetLow: targetLow,
      targetHigh: targetHigh,
      units: units,
      timezone: json['timezone'],
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

    return TimeValue(
      time: timeOfDay,
      value: json['value'].toDouble(),
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

  factory TimeValues.fromJson(List<dynamic> json) {
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
