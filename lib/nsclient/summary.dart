import 'dart:convert';

import 'package:carer/models/settings_cn.dart';
import 'package:carer/utils/dates.dart';
import 'package:carer/utils/errors.dart';
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:unicons/unicons.dart';

const MGtoMMOL = 18.018;

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

  TimeValues map(TimeValue Function(TimeValue) f) {
    List<TimeValue> newValues = values.map(f).toList();
    return TimeValues(values: newValues);
  }

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
        return (sgv / MGtoMMOL).toStringAsFixed(1);
    }
  }
}

abstract class ATreatment {
  DateTime get date;
  IconData get icon;
  Duration get age {
    return DateTime.now().difference(date);
  }
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
    if (insulin != null && insulin != 0) {
      return '${insulin!.toStringAsFixed(2)}u';
    } else {
      return "";
    }
  }

  String get carbStr {
    if (carbs != null && carbs != 0) {
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

class TempTarget extends ATreatment {
  int targetTop;
  int targetBottom;
  int duration;
  DateTime mills;

  TempTarget({
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

  Duration get remaining {
    return dateEnd.difference(DateTime.now());
  }

  factory TempTarget.fromJson(Map<String, dynamic> json) {
    return TempTarget(
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
    return tempBasals.lastWhereOrNull((element) =>
        date.isAfter(element.date) && date.isBefore(element.dateEnd));
  }
}

class Targets {
  final List<TempTarget> targets;

  const Targets({
    required this.targets,
  });

  factory Targets.fromJson(List<dynamic> json) {
    List<TempTarget> targets =
        json.map((targetJson) => TempTarget.fromJson(targetJson)).toList();
    targets.sort((a, b) => a.date.compareTo(b.date));
    return Targets(targets: targets);
  }

  TempTarget? atDate(DateTime date) {
    return targets.lastWhereOrNull((element) =>
        date.isAfter(element.date) && date.isBefore(element.dateEnd));
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

  List<SummaryTreatment> summarizedTreatments(int minsAgo, int window) {
    List<SummaryTreatment> spots = [];
    var lastTreatments = lastMins(minsAgo);
    var now = DateTime.now();
    // always start the window in the same place to make sure the same treatments are grouped together
    var startDate = now.subtract(Duration(minutes: minsAgo));

    // This is not 100% efficient because it always scans at least an hour, but this is the easiest for now
    var startWindow = DateTime(
        startDate.year, startDate.month, startDate.day, startDate.hour, 0);
    var endWindow = DateTime(
        startDate.year, startDate.month, startDate.day, startDate.hour, window);
    // We are going to group all treatments into 5 minute window blocks to make it more readable
    while (startWindow.isBefore(now)) {
      var treatments = lastTreatments.where((t) =>
          (t.date.isAfter(startWindow) || t.date == startWindow) &&
          t.date.isBefore(endWindow));

      var oldStartwindow = startWindow;
      startWindow = endWindow;
      endWindow = endWindow.add(Duration(minutes: window));

      if (treatments.isEmpty) {
        continue;
      }

      var insulin = treatments
          .where((t) => t.insulin != null)
          .map((t) => t.insulin!)
          .fold(0.0, (a, b) => a + b);
      var carbs = treatments
          .where((t) => t.carbs != null)
          .map((t) => t.carbs!)
          .fold(0, (a, b) => a + b);
      var newSummary = SummaryTreatment(
          insulin: insulin, carbs: carbs, mills: oldStartwindow);

      spots.add(newSummary);
    }
    spots.sort((a, b) => b.date.compareTo(a.date));
    return spots;
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

    return Profile(
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

    return (basal, tempBasal);
  }

  (TimeValue?, TimeValue?, TempTarget?) targetAtTime(DateTime date) {
    var temptarget = targets.atDate(date);
    var profileTargetLow = profile.targetLow.atDate(date);
    var profileTargetHigh = profile.targetHigh.atDate(date);

    return (profileTargetLow, profileTargetHigh, temptarget);
  }

  // return a list of tempBasals treatments and targets in order
  List<ATreatment> history() {
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
              const Duration(hours: 24),
            )))
        .toList();

    return history;
  }
}
