import 'dart:convert';

import 'package:carer/models/constants.dart';
import 'package:carer/utils/dates.dart';
import 'package:carer/utils/errors.dart';
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';

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
    List<TimeValue> values =
        json.map((valueJson) => TimeValue.fromJson(valueJson)).toList();

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

class SummarySGV {
  final int sgv;
  final DateTime mills;

  SummarySGV({
    required this.sgv,
    required this.mills,
  });

  get date => mills;

  factory SummarySGV.fromJson(Map<String, dynamic> json) {
    return SummarySGV(
      sgv: json['sgv'],
      mills: DateTime.fromMillisecondsSinceEpoch(json['mills']),
    );
  }
}

class SummaryTempBasal {
  DateTime start;
  double duration;
  double absolute;

  SummaryTempBasal({
    required this.start,
    required this.duration,
    required this.absolute,
  });

  factory SummaryTempBasal.fromJson(Map<String, dynamic> json) {
    return SummaryTempBasal(
      start: DateTime.fromMillisecondsSinceEpoch(json['start']),
      duration: json['duration'].toDouble(),
      absolute: json['absolute'].toDouble(),
    );
  }
}

class SummaryTreatment {
  DateTime date;
  double? insulin;
  int? carbs;

  SummaryTreatment({
    required this.date,
    this.insulin,
    this.carbs,
  });

  factory SummaryTreatment.fromJson(Map<String, dynamic> json) {
    return SummaryTreatment(
      date: DateTime.fromMillisecondsSinceEpoch(json['mills']),
      insulin: json['insulin']?.toDouble(),
      carbs: json['carbs'],
    );
  }
}

class SummaryTempTarget {
  int targetTop;
  int targetBottom;
  int duration;
  DateTime start;

  SummaryTempTarget({
    required this.targetTop,
    required this.targetBottom,
    required this.duration,
    required this.start,
  });

  factory SummaryTempTarget.fromJson(Map<String, dynamic> json) {
    return SummaryTempTarget(
      targetTop: json['targetTop'],
      targetBottom: json['targetBottom'],
      duration: json['duration'],
      start: json['mills'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['mills'])
          : Dates.earliest,
    );
  }
}

class SummaryState {
  final double? iob;
  final int? cob;
  final double? bwp;
  final int? cage;
  final int? iage;
  final int? bage;
  final int? battery;

  const SummaryState({
    required this.iob,
    required this.cob,
    required this.bwp,
    required this.cage,
    required this.iage,
    required this.bage,
    required this.battery,
  });

  factory SummaryState.fromJson(Map<String, dynamic> json) {
    return SummaryState(
      iob: (json['iob'] ?? 0).toDouble(),
      cob: json['cob'],
      bwp: (json['bwp'] ?? 0).toDouble(),
      cage: json['cage'],
      iage: json['iage'],
      bage: json['bage'],
      battery: json['battery'],
    );
  }
}

class SummarySGVs {
  final List<SummarySGV> sgvs;

  const SummarySGVs({
    required this.sgvs,
  });

  factory SummarySGVs.fromJson(List<dynamic> json) {
    List<SummarySGV> sgvs =
        json.map((sgvJson) => SummarySGV.fromJson(sgvJson)).toList();

    return SummarySGVs(sgvs: sgvs);
  }
}

class TempBasals {
  final List<SummaryTempBasal> tempBasals;

  const TempBasals({
    required this.tempBasals,
  });

  factory TempBasals.fromJson(List<dynamic> json) {
    List<SummaryTempBasal> tempBasals = [];
    for (var tempBasalJson in json) {
      if (tempBasalJson['start'] == null) {
        continue;
      }
      if (tempBasalJson['duration'] == null) {
        continue;
      }
      tempBasals.add(SummaryTempBasal.fromJson(tempBasalJson));
    }

    return TempBasals(tempBasals: tempBasals);
  }
}

class SummaryTargets {
  final List<SummaryTempTarget> targets;

  const SummaryTargets({
    required this.targets,
  });

  factory SummaryTargets.fromJson(List<dynamic> json) {
    List<SummaryTempTarget> targets = [];
    for (var targetJson in json) {
      if (targetJson['mills'] == null) {
        continue;
      }
      if (targetJson['duration'] == null) {
        continue;
      }
      targets.add(SummaryTempTarget.fromJson(targetJson));
    }

    return SummaryTargets(targets: targets);
  }
}

class SummaryTreatments {
  final List<SummaryTreatment> treatments;

  const SummaryTreatments({
    required this.treatments,
  });

  factory SummaryTreatments.fromJson(List<dynamic> json) {
    List<SummaryTreatment> treatments = json
        .map((treatmentJson) => SummaryTreatment.fromJson(treatmentJson))
        .toList();
    return SummaryTreatments(treatments: treatments);
  }

  List<SummaryTreatment> boluses() {
    return treatments.where((t) => t.insulin != null).toList();
  }

  List<SummaryTreatment> carbs() {
    return treatments.where((t) => t.carbs != null).toList();
  }
}

class SummaryProfile {
  final int dia;
  final TimeValues carbratio;
  final TimeValues sens;
  final TimeValues basal;
  final TimeValues targetLow;
  final TimeValues targetHigh;
  final String units;
  final String timezone;

  const SummaryProfile({
    required this.dia,
    required this.carbratio,
    required this.sens,
    required this.basal,
    required this.targetLow,
    required this.targetHigh,
    required this.units,
    required this.timezone,
  });

  List<int> expandedCarbratio() =>
      carbratio.expand().map((e) => e.round()).toList();
  List<int> expandedSens() => sens.expand().map((e) => e.round()).toList();
  List<double> expandedBasal() => basal.expand();
  List<int> expandedTargetLow() =>
      targetLow.expand().map((e) => e.round()).toList();
  List<int> expandedTargetHigh() =>
      targetHigh.expand().map((e) => e.round()).toList();

  factory SummaryProfile.fromJson(Map<String, dynamic> json) {
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

    return SummaryProfile(
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

class Summary {
  final int dateRetrievedmills;
  final SummarySGVs sgvs;
  final TempBasals tempBasals;
  final SummaryTreatments treatments;
  final SummaryTargets targets;
  final SummaryState state;
  final SummaryProfile profile;
  final String raw;

  const Summary({
    required this.raw,
    required this.sgvs,
    required this.tempBasals,
    required this.treatments,
    required this.targets,
    required this.state,
    required this.profile,
    required this.dateRetrievedmills,
  });

  static const Summary empty = Summary(
      raw: "",
      sgvs: SummarySGVs(sgvs: []),
      tempBasals: TempBasals(tempBasals: []),
      treatments: SummaryTreatments(treatments: []),
      targets: SummaryTargets(targets: []),
      state: SummaryState(
        iob: 0,
        cob: 0,
        bwp: 0,
        cage: 0,
        iage: 0,
        bage: 0,
        battery: 0,
      ),
      profile: SummaryProfile(
          dia: 1,
          carbratio: TimeValues(values: []),
          sens: TimeValues(values: []),
          basal: TimeValues(values: []),
          targetLow: TimeValues(values: []),
          targetHigh: TimeValues(values: []),
          units: "",
          timezone: ""),
      dateRetrievedmills: 0);

  factory Summary.fromJson(String jsonString) {
    try {
      var json = jsonDecode(jsonString);
      return Summary(
        raw: jsonString,
        sgvs: SummarySGVs.fromJson(json['sgvs']),
        tempBasals: TempBasals.fromJson(json['treatments']['tempBasals']),
        treatments:
            SummaryTreatments.fromJson(json['treatments']['treatments']),
        targets: SummaryTargets.fromJson(json['treatments']['targets']),
        state: SummaryState.fromJson(json['state']),
        profile: SummaryProfile.fromJson(json['profile']),
        dateRetrievedmills: clock.now().millisecondsSinceEpoch,
      );
    } catch (e, stackTrace) {
      Errors.captureException(e, stackTrace: stackTrace);
      return Summary.empty;
    }
  }

  DateTime get dateRetrieved {
    return DateTime.fromMillisecondsSinceEpoch(dateRetrievedmills);
  }

  int ageInSeconds() {
    return clock.now().difference(dateRetrieved).inSeconds;
  }
}
