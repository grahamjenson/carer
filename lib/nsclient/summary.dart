import 'dart:convert';

import 'package:carer/models/settings_cn.dart';
import 'package:carer/utils/dates.dart';
import 'package:carer/utils/errors.dart';
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:unicons/unicons.dart';

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

  bool isBefore(DateTime date) {
    // make DateTime from time
    var dateTime =
        DateTime(date.year, date.month, date.day, time.hour, time.minute);
    return dateTime.isBefore(date);
  }

  // compareTo to compare two TimeValues
  int compareTo(TimeValue other) {
    // lexicographically ordered for hour then minute
    return time.hour * 60 +
        time.minute -
        (other.time.hour * 60 + other.time.minute);
  }

  @override
  String toString() {
    return "TimeValue: $time, $value";
  }
}

class TimeValues {
  final List<TimeValue> values;

  const TimeValues({
    required this.values,
  });

  factory TimeValues.fromJson(List<dynamic> json) {
    List<TimeValue> values =
        json.map((valueJson) => TimeValue.fromJson(valueJson)).toList();

    // Sort this to make the TimeValues chronologically ordered
    values.sort((a, b) => a.compareTo(b));
    return TimeValues(values: values);
  }

  TimeValue? atDate(DateTime date) {
    return values.lastWhereOrNull(
      (element) => element.isBefore(date),
    );
  }
}

class SGV {
  final int sgv;
  DateTime mills;

  SGV({
    required this.sgv,
    required this.mills,
  });

  get date => mills;

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
    return unit.val(sgv);
  }

  String sgvUWithSign(Unit unit) {
    var sgv = sgvU(unit);
    var sgvStr = sgv.toStringAsFixed(1);
    if (sgv == 0) {
      sgvStr = "+0";
    } else if (sgv > 0) {
      sgvStr = "+${sgv.toStringAsFixed(1)}";
    }
    return sgvStr;
  }

  String sgvStr(Unit unit) {
    switch (unit) {
      case Unit.mg:
        return sgv.toString();
      case Unit.mmol:
        return (sgv / 18.018).toStringAsFixed(1);
    }
  }
}

abstract class ATreatment {
  Unit unit = Unit.mg;

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

  //return the date + duration in seconds as a DateTime
  DateTime get dateEnd {
    return date.add(Duration(seconds: duration.toInt()));
  }

  Duration get remaining {
    return dateEnd.difference(DateTime.now());
  }

  @override
  String get description {
    return "${absolute.toStringAsFixed(2)}u ${Dates.dateAgoShort(remaining, hours: false)}";
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
    if (insulin != null && carbs != null) {
      return UniconsLine.anchor;
    } else if (insulin != null) {
      return UniconsLine.syringe;
    } else {
      return Icons.fastfood;
    }
  }

  String get insulinStr {
    if (insulin != null) {
      return '${insulin!.toStringAsFixed(2)}u';
    } else {
      return "";
    }
  }

  String get carbStr {
    if (carbs != null) {
      return '${carbs!.toStringAsFixed(0)}g';
    } else {
      return "";
    }
  }

  @override
  String get description {
    if (insulin != null && carbs != null) {
      return "$insulinStr, $carbStr";
    } else if (insulin != null) {
      return insulinStr;
    } else if (carbs != null) {
      return carbStr;
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

  //return the date + duration in seconds as a DateTime
  DateTime get dateEnd {
    return date.add(Duration(seconds: duration));
  }

  @override
  String get description {
    if (targetBottom == targetTop) {
      return "${unit.str(targetBottom)}${unit.name}";
    }
    return "${unit.str(targetBottom)}-${unit.str(targetTop)}${unit.name}";
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
    // sort sgvs by age
    sgvs.sort((a, b) => a.mills.compareTo(b.mills));

    return SGVs(sgvs: sgvs);
  }

  // return the last sgvs for minutes
  List<SGV> lastMins(int minutes) {
    return sgvs.where((sgv) => sgv.age.inMinutes < minutes).toList();
  }

  SGV? delta() {
    if (sgvs.length < 2) {
      return null;
    }

    // also sanity check the last two sgvs
    // second most recent sgv should be within 5 minutes of most recent
    var last = sgvs.last;
    var secondLast = sgvs[sgvs.length - 2];

    if ((secondLast.age.inMinutes - last.age.inMinutes).abs() > 6) {
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
    tempBasals.sort((a, b) => a.date.compareTo(b.date));
    return TempBasals(tempBasals: tempBasals);
  }

  TempBasal? atDate(DateTime date) {
    return tempBasals
        .lastWhereOrNull((element) => element.start.isBefore(date));
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

  // return the last treatments for minutes
  List<SummaryTreatment> lastMins(int minutes) {
    return treatments
        .where((treatment) => treatment.age.inMinutes < minutes)
        .toList();
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
    targets.sort((a, b) => a.date.compareTo(b.date));
    return Targets(targets: targets);
  }
}

class Profile {
  final int dia;
  final TimeValues carbratio;
  final TimeValues sens;
  final TimeValues basal;
  final TimeValues targetLow;
  final TimeValues targetHigh;
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
      carbratio: TimeValues.fromJson(json['carbratio']),
      sens: TimeValues.fromJson(json['sens']),
      basal: TimeValues.fromJson(json['basal']),
      targetLow: TimeValues.fromJson(json['target_low']),
      targetHigh: TimeValues.fromJson(json['target_high']),
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

  (TimeValue?, TempBasal?) basalAtTime(DateTime date) {
    var tempBasal = tempBasals.atDate(date);
    var basal = profile.basal.atDate(date);
    if (tempBasal != null) {
      return (basal, tempBasal);
    }

    return (basal, null);
  }

  Target? get lastTarget {
    if (targets.targets.isEmpty) {
      return null;
    }
    var lastTarget = targets.targets.last;

    // if the last target dateEnd is in the past, return null
    if (DateTime.now().isBefore(lastTarget.dateEnd)) {
      return lastTarget;
    }

    return null;
  }

  // return a list of tempBasals treatments and targets in order
  List<ATreatment> history(Unit unit) {
    List<ATreatment> history = [];

    // add the tempBasals
    history.addAll(tempBasals.tempBasals);

    // add the treatments
    history.addAll(treatments.treatments);

    // add the targets
    history.addAll(targets.targets);

    // sort the history by date
    history.sort((a, b) => b.date.compareTo(a.date));

    // loop over all the treatments and convert them to the correct unit
    history = history.map((treatment) {
      treatment.unit = unit;
      return treatment;
    }).toList();

    // filter history to items that only happend in late 6 hours
    history = history
        .where((element) => element.date.isAfter(DateTime.now().subtract(
              const Duration(hours: 24),
            )))
        .toList();

    return history;
  }
}
