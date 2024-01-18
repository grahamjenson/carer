import 'dart:convert';

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
}

class TempBasal {
  DateTime start;
  int duration;
  double absolute;

  TempBasal({
    required this.start,
    required this.duration,
    required this.absolute,
  });

  factory TempBasal.fromJson(Map<String, dynamic> json) {
    return TempBasal(
      start: DateTime.fromMillisecondsSinceEpoch(json['start']),
      duration: json['duration'],
      absolute: json['absolute'].toDouble(),
    );
  }
}

class Treatment {
  DateTime mills;
  double? insulin;
  int? carbs;

  Treatment({
    required this.mills,
    this.insulin,
    this.carbs,
  });

  factory Treatment.fromJson(Map<String, dynamic> json) {
    return Treatment(
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

class State {
  double iob;
  int cob;
  double bwp;
  int cage;
  int iage;
  int bage;
  int battery;

  State({
    required this.iob,
    required this.cob,
    required this.bwp,
    required this.cage,
    required this.iage,
    required this.bage,
    required this.battery,
  });

  factory State.fromJson(Map<String, dynamic> json) {
    return State(
      iob: json['iob'],
      cob: json['cob'],
      bwp: json['bwp'],
      cage: json['cage'],
      iage: json['iage'],
      bage: json['bage'],
      battery: json['battery'],
    );
  }
}

class SGVCollection {
  List<SGV> sgvs;

  SGVCollection({
    required this.sgvs,
  });

  factory SGVCollection.fromJson(List<dynamic> json) {
    List<SGV> sgvs = json.map((sgvJson) => SGV.fromJson(sgvJson)).toList();
    return SGVCollection(sgvs: sgvs);
  }
}

class TempBasalCollection {
  List<TempBasal> tempBasals;

  TempBasalCollection({
    required this.tempBasals,
  });

  factory TempBasalCollection.fromJson(List<dynamic> json) {
    List<TempBasal> tempBasals =
        json.map((tempBasalJson) => TempBasal.fromJson(tempBasalJson)).toList();
    return TempBasalCollection(tempBasals: tempBasals);
  }
}

class TreatmentCollection {
  List<Treatment> treatments;

  TreatmentCollection({
    required this.treatments,
  });

  factory TreatmentCollection.fromJson(List<dynamic> json) {
    List<Treatment> treatments =
        json.map((treatmentJson) => Treatment.fromJson(treatmentJson)).toList();
    return TreatmentCollection(treatments: treatments);
  }
}

class TargetCollection {
  List<Target> targets;

  TargetCollection({
    required this.targets,
  });

  factory TargetCollection.fromJson(List<dynamic> json) {
    List<Target> targets =
        json.map((targetJson) => Target.fromJson(targetJson)).toList();
    return TargetCollection(targets: targets);
  }
}

class StateCollection {
  State state;

  StateCollection({
    required this.state,
  });

  factory StateCollection.fromJson(Map<String, dynamic> json) {
    return StateCollection(state: State.fromJson(json));
  }
}

class Summary {
  SGVCollection sgvs;
  TempBasalCollection tempBasals;
  TreatmentCollection treatments;
  TargetCollection targets;
  StateCollection state;

  Summary({
    required this.sgvs,
    required this.tempBasals,
    required this.treatments,
    required this.targets,
    required this.state,
  });

  factory Summary.fromJson(String jsonString) {
    var json = jsonDecode(jsonString);
    return Summary(
      sgvs: SGVCollection.fromJson(json['sgvs']),
      tempBasals:
          TempBasalCollection.fromJson(json['treatments']['tempBasals']),
      treatments:
          TreatmentCollection.fromJson(json['treatments']['treatments']),
      targets: TargetCollection.fromJson(json['treatments']['targets']),
      state: StateCollection.fromJson(json['state']),
    );
  }
}
