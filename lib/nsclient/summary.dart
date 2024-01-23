import 'dart:convert';
import 'dart:developer';

import 'package:carer/models/settings_cn.dart';
import 'package:carer/nsclient/shared.dart';
import 'package:carer/utils/dates.dart';
import 'package:carer/utils/errors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class SGV {
  int sgv;
  DateTime mills;

  SGV({
    required this.sgv,
    required this.mills,
  });

  factory SGV.fromJson(Map<String, dynamic> json) {
    return SGV(
      sgv: json['sgv'],
      mills: DateTime.fromMillisecondsSinceEpoch(json['mills']),
    );
  }

  // returns the date in minutes ago format
  String get dateAgo {
    return Dates.dateAgoFromMills(mills);
  }

  double sgvU(Unit unit) {
    switch (unit) {
      case Unit.mg:
        return sgv.toDouble();
      case Unit.mmol:
        return (sgv / 18).toDouble();
    }
  }
}

class TempBasal {
  DateTime start;
  double duration;
  double absolute;

  TempBasal({
    required this.start,
    required this.duration,
    required this.absolute,
  });

  factory TempBasal.fromJson(Map<String, dynamic> json) {
    return TempBasal(
      start: DateTime.fromMillisecondsSinceEpoch(json['start']),
      duration: json['duration'].toDouble(),
      absolute: json['absolute'].toDouble(),
    );
  }
}

class SummaryTreatment {
  DateTime mills;
  double? insulin;
  int? carbs;

  SummaryTreatment({
    required this.mills,
    this.insulin,
    this.carbs,
  });

  factory SummaryTreatment.fromJson(Map<String, dynamic> json) {
    return SummaryTreatment(
      mills: DateTime.fromMillisecondsSinceEpoch(json['mills']),
      insulin: json['insulin']?.toDouble(),
      carbs: json['carbs'],
    );
  }
}

class Target {
  int targetTop;
  int targetBottom;
  int duration;
  DateTime? mills;

  Target({
    required this.targetTop,
    required this.targetBottom,
    required this.duration,
    this.mills,
  });

  factory Target.fromJson(Map<String, dynamic> json) {
    return Target(
      targetTop: json['targetTop'],
      targetBottom: json['targetBottom'],
      duration: json['duration'],
      mills: json['mills'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['mills'])
          : null,
    );
  }
}

class SummaryState {
  double iob;
  int cob;
  double bwp;
  int cage;
  int iage;
  int bage;
  int battery;

  SummaryState({
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
      iob: json['iob'].toDouble(),
      cob: json['cob'],
      bwp: json['bwp'].toDouble(),
      cage: json['cage'],
      iage: json['iage'],
      bage: json['bage'],
      battery: json['battery'],
    );
  }
}

class SGVs {
  List<SGV> sgvs;

  SGVs({
    required this.sgvs,
  });

  factory SGVs.fromJson(List<dynamic> json) {
    List<SGV> sgvs = json.map((sgvJson) => SGV.fromJson(sgvJson)).toList();
    return SGVs(sgvs: sgvs);
  }
}

class TempBasals {
  List<TempBasal> tempBasals;

  TempBasals({
    required this.tempBasals,
  });

  factory TempBasals.fromJson(List<dynamic> json) {
    List<TempBasal> tempBasals =
        json.map((tempBasalJson) => TempBasal.fromJson(tempBasalJson)).toList();
    return TempBasals(tempBasals: tempBasals);
  }
}

class SummaryTreatments {
  List<SummaryTreatment> treatments;

  SummaryTreatments({
    required this.treatments,
  });

  factory SummaryTreatments.fromJson(List<dynamic> json) {
    List<SummaryTreatment> treatments = json
        .map((treatmentJson) => SummaryTreatment.fromJson(treatmentJson))
        .toList();
    return SummaryTreatments(treatments: treatments);
  }
}

class Targets {
  List<Target> targets;

  Targets({
    required this.targets,
  });

  factory Targets.fromJson(List<dynamic> json) {
    List<Target> targets =
        json.map((targetJson) => Target.fromJson(targetJson)).toList();
    return Targets(targets: targets);
  }
}

class Profile {
  int dia;
  List<TimeValue> carbratio;
  List<TimeValue> sens;
  List<TimeValue> basal;
  List<TimeValue> targetLow;
  List<TimeValue> targetHigh;
  String units;
  String timezone;

  Profile({
    required this.dia,
    required this.carbratio,
    required this.sens,
    required this.basal,
    required this.targetLow,
    required this.targetHigh,
    required this.units,
    required this.timezone,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      dia: json['dia'],
      carbratio: List<TimeValue>.from(
          json['carbratio'].map((item) => TimeValue.fromJson(item))),
      sens: List<TimeValue>.from(
          json['sens'].map((item) => TimeValue.fromJson(item))),
      basal: List<TimeValue>.from(
          json['basal'].map((item) => TimeValue.fromJson(item))),
      targetLow: List<TimeValue>.from(
          json['target_low'].map((item) => TimeValue.fromJson(item))),
      targetHigh: List<TimeValue>.from(
          json['target_high'].map((item) => TimeValue.fromJson(item))),
      units: json['units'],
      timezone: json['timezone'],
    );
  }
}

class Summary {
  DateTime dateRetrieved = DateTime.now();
  final SGVs sgvs;
  final TempBasals tempBasals;
  final SummaryTreatments treatments;
  final Targets targets;
  final SummaryState state;
  final Profile profile;

  Summary({
    required this.sgvs,
    required this.tempBasals,
    required this.treatments,
    required this.targets,
    required this.state,
    required this.profile,
    DateTime? dateRetrieved,
  }) {
    if (dateRetrieved != null) {
      this.dateRetrieved = dateRetrieved;
    }
  }

  factory Summary.empty() {
    return Summary(
        sgvs: SGVs(sgvs: []),
        tempBasals: TempBasals(tempBasals: []),
        treatments: SummaryTreatments(treatments: []),
        targets: Targets(targets: []),
        state: SummaryState(
          iob: 0,
          cob: 0,
          bwp: 0,
          cage: 0,
          iage: 0,
          bage: 0,
          battery: 0,
        ),
        profile: Profile(
            dia: 1,
            carbratio: [],
            sens: [],
            basal: [],
            targetLow: [],
            targetHigh: [],
            units: "",
            timezone: ""),
        dateRetrieved: Dates.earliest);
  }

  factory Summary.fromJson(String jsonString) {
    try {
      var json = jsonDecode(jsonString);
      return Summary(
        sgvs: SGVs.fromJson(json['sgvs']),
        tempBasals: TempBasals.fromJson(json['treatments']['tempBasals']),
        treatments:
            SummaryTreatments.fromJson(json['treatments']['treatments']),
        targets: Targets.fromJson(json['treatments']['targets']),
        state: SummaryState.fromJson(json['state']),
        profile: Profile.fromJson(json['profile']),
      );
    } catch (e, stackTrace) {
      Errors.captureException(e, stackTrace: stackTrace);
      return Summary.empty();
    }
  }

  // function returns the last SGV
  SGV? get lastSGV {
    if (sgvs.sgvs.isEmpty) {
      return null;
    }
    return sgvs.sgvs.last;
  }

  double delta(Unit unit) {
    if (sgvs.sgvs.length < 2) {
      return 0;
    }
    return (sgvs.sgvs.last.sgvU(unit) -
            sgvs.sgvs[sgvs.sgvs.length - 2].sgvU(unit))
        .toDouble();
  }

  IconData get trendIcon {
    if (sgvs.sgvs.length < 2) {
      return Icons.trending_flat;
    }
    var delta = sgvs.sgvs.last.sgv - sgvs.sgvs[sgvs.sgvs.length - 2].sgv;
    if (delta > 0) {
      return Icons.trending_up;
    } else if (delta < 0) {
      return Icons.trending_down;
    } else {
      return Icons.trending_flat;
    }
  }

  int ageInSeconds() {
    return DateTime.now().difference(dateRetrieved).inSeconds;
  }
}
