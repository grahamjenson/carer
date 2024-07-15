import 'dart:convert';

import 'package:carer/nsclient/shared.dart';
import 'package:carer/utils/dates.dart';
import 'package:carer/utils/logs.dart';
import 'package:clock/clock.dart';

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
      start: json['mills'] != null ? DateTime.fromMillisecondsSinceEpoch(json['mills']) : Dates.earliest,
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
    List<SummarySGV> sgvs = json.map((sgvJson) => SummarySGV.fromJson(sgvJson)).toList();

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
    List<SummaryTreatment> treatments = json.map((treatmentJson) => SummaryTreatment.fromJson(treatmentJson)).toList();
    return SummaryTreatments(treatments: treatments);
  }

  List<SummaryTreatment> boluses() {
    return treatments.where((t) => t.insulin != null).toList();
  }

  List<SummaryTreatment> carbs() {
    return treatments.where((t) => t.carbs != null).toList();
  }
}

class Summary {
  final SummarySGVs sgvs;
  final TempBasals tempBasals;
  final SummaryTreatments treatments;
  final SummaryTargets targets;
  final SummaryState state;
  final NSProfile profile;
  final String raw;

  const Summary({
    required this.raw,
    required this.sgvs,
    required this.tempBasals,
    required this.treatments,
    required this.targets,
    required this.state,
    required this.profile,
  });

  static Summary? fromJson(String jsonString) {
    try {
      var json = jsonDecode(jsonString);
      return Summary(
        raw: jsonString,
        sgvs: SummarySGVs.fromJson(json['sgvs']),
        tempBasals: TempBasals.fromJson(json['treatments']['tempBasals']),
        treatments: SummaryTreatments.fromJson(json['treatments']['treatments']),
        targets: SummaryTargets.fromJson(json['treatments']['targets']),
        state: SummaryState.fromJson(json['state']),
        profile: NSProfile.fromJson("unknown", "id", clock.now(), json['profile']),
      );
    } catch (e, stackTrace) {
      Errors.captureError(e, stackTrace);
      return null;
    }
  }
}
