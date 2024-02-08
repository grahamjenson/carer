import 'dart:convert';
import 'dart:developer';

import 'package:carer/models/settings_cn.dart';
import 'package:carer/nsclient/shared.dart';
import 'package:carer/utils/dates.dart';
import 'package:carer/utils/errors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'package:unicons/unicons.dart';

class SGV {
  final int sgv;
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

  Duration get age {
    return DateTime.now().difference(mills);
  }

  double sgvU(Unit unit) {
    switch (unit) {
      case Unit.mg:
        return sgv.toDouble();
      case Unit.mmol:
        return (sgv / 18).toDouble();
    }
  }

  String sgvStr(Unit unit) {
    switch (unit) {
      case Unit.mg:
        return sgv.toString();
      case Unit.mmol:
        return (sgv / 18).toStringAsFixed(1);
    }
  }
}

abstract class ATreatment {
  DateTime get date;
  IconData get icon;
  Duration get age {
    return DateTime.now().difference(date);
  }

  String get description;
}

class TempBasal extends ATreatment {
  DateTime start;
  double duration;
  double absolute;

  TempBasal({
    required this.start,
    required this.duration,
    required this.absolute,
  });

  @override
  DateTime get date => start;

  @override
  IconData get icon => Icons.access_time;

  @override
  String get description {
    return "Temp Basal $absolute";
  }

  factory TempBasal.fromJson(Map<String, dynamic> json) {
    return TempBasal(
      start: DateTime.fromMillisecondsSinceEpoch(json['start']),
      duration: json['duration'].toDouble(),
      absolute: json['absolute'].toDouble(),
    );
  }
}

class SummaryTreatment extends ATreatment {
  DateTime mills;
  double? insulin;
  int? carbs;

  SummaryTreatment({
    required this.mills,
    this.insulin,
    this.carbs,
  });

  @override
  DateTime get date => mills;

  @override
  IconData get icon {
    if (insulin != null) {
      return UniconsLine.syringe;
    } else {
      return Icons.fastfood;
    }
  }

  @override
  String get description {
    if (insulin != null) {
      return insulin.toString();
    } else if (carbs != null) {
      return carbs.toString();
    } else {
      return "";
    }
  }

  factory SummaryTreatment.fromJson(Map<String, dynamic> json) {
    return SummaryTreatment(
      mills: DateTime.fromMillisecondsSinceEpoch(json['mills']),
      insulin: json['insulin']?.toDouble(),
      carbs: json['carbs'],
    );
  }
}

class Target extends ATreatment {
  int targetTop;
  int targetBottom;
  int duration;
  DateTime mills;

  Target({
    required this.targetTop,
    required this.targetBottom,
    required this.duration,
    required this.mills,
  });

  @override
  DateTime get date => mills;

  @override
  IconData get icon => Icons.trending_flat;

  @override
  String get description {
    return targetTop.toString();
  }

  factory Target.fromJson(Map<String, dynamic> json) {
    return Target(
      targetTop: json['targetTop'],
      targetBottom: json['targetBottom'],
      duration: json['duration'],
      mills: json['mills'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['mills'])
          : Dates.earliest,
    );
  }
}

class SummaryState {
  final double iob;
  final int cob;
  final double bwp;
  final int cage;
  final int iage;
  final int bage;
  final int battery;

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
  final List<SGV> sgvs;

  const SGVs({
    required this.sgvs,
  });

  factory SGVs.fromJson(List<dynamic> json) {
    List<SGV> sgvs = json.map((sgvJson) => SGV.fromJson(sgvJson)).toList();
    return SGVs(sgvs: sgvs);
  }

  SGV? delta() {
    if (sgvs.length < 2) {
      return null;
    }

    // also sanity check the last two sgvs
    // second most recent sgv should be within 5 minutes of most recent
    var last = sgvs.last;
    var secondLast = sgvs[sgvs.length - 2];

    if ((secondLast.age.inMinutes - last.age.inMinutes).abs() > 5) {
      return null;
    }

    return SGV(mills: last.mills, sgv: last.sgv - secondLast.sgv);
  }
}

class TempBasals {
  final List<TempBasal> tempBasals;

  const TempBasals({
    required this.tempBasals,
  });

  factory TempBasals.fromJson(List<dynamic> json) {
    List<TempBasal> tempBasals =
        json.map((tempBasalJson) => TempBasal.fromJson(tempBasalJson)).toList();
    return TempBasals(tempBasals: tempBasals);
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
}

class Targets {
  final List<Target> targets;

  const Targets({
    required this.targets,
  });

  factory Targets.fromJson(List<dynamic> json) {
    List<Target> targets =
        json.map((targetJson) => Target.fromJson(targetJson)).toList();
    return Targets(targets: targets);
  }
}

class Profile {
  final int dia;
  final List<TimeValue> carbratio;
  final List<TimeValue> sens;
  final List<TimeValue> basal;
  final List<TimeValue> targetLow;
  final List<TimeValue> targetHigh;
  final String units;
  final String timezone;

  const Profile({
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
  final int dateRetrievedmills;
  final SGVs sgvs;
  final TempBasals tempBasals;
  final SummaryTreatments treatments;
  final Targets targets;
  final SummaryState state;
  final Profile profile;

  const Summary({
    required this.sgvs,
    required this.tempBasals,
    required this.treatments,
    required this.targets,
    required this.state,
    required this.profile,
    required this.dateRetrievedmills,
  });

  static const Summary empty = Summary(
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
      dateRetrievedmills: 0);

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
        dateRetrievedmills: DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e, stackTrace) {
      Errors.captureException(e, stackTrace: stackTrace);
      return Summary.empty;
    }
  }

  DateTime get dateRetrieved {
    return DateTime.fromMillisecondsSinceEpoch(dateRetrievedmills);
  }

  // function returns the last SGV
  SGV? get lastSGV {
    if (sgvs.sgvs.isEmpty) {
      return null;
    }
    return sgvs.sgvs.last;
  }

  SGV? get delta {
    return sgvs.delta();
  }

  int ageInSeconds() {
    return DateTime.now().difference(dateRetrieved).inSeconds;
  }

  // return a list of tempBasals treatments and targets in order
  List<ATreatment> get history {
    List<ATreatment> history = [];

    // add the tempBasals
    history.addAll(tempBasals.tempBasals);

    // add the treatments
    history.addAll(treatments.treatments);

    // add the targets
    history.addAll(targets.targets);

    // sort the history by date
    history.sort((a, b) => b.date.compareTo(a.date));

    // filter history to items that only happend in late 6 hours
    history = history
        .where((element) => element.date.isAfter(DateTime.now().subtract(
              const Duration(hours: 6),
            )))
        .toList();

    return history;
  }
}
