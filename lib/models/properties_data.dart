import 'package:carer/utils/futures.dart';

enum PropertiesDataName {
  t1dPhoneBattery,
  t1dPhoneCharging,
  iob,
  basaliob,
  treatmentiob,
  cob,
  cage,
  sage,
  reservoir,
}

class PropertiesData {
  static final PropertiesData _singleton = PropertiesData._();
  factory PropertiesData() => _singleton;
  PropertiesData._();

  final Map<PropertiesDataName, ASignal<double?>> _doubleSignals = {
    PropertiesDataName.iob: ASignal<double?>(null, debugLabel: "IOB"),
    PropertiesDataName.basaliob: ASignal<double?>(null, debugLabel: "BasalIOB"),
    PropertiesDataName.treatmentiob: ASignal<double?>(null, debugLabel: "TreatmentiOB"),
    PropertiesDataName.cob: ASignal<double?>(null, debugLabel: "COB"),
    PropertiesDataName.reservoir: ASignal<double?>(null, debugLabel: "Reservoir"),
  };

  final Map<PropertiesDataName, ASignal<bool?>> _boolSignals = {
    PropertiesDataName.t1dPhoneCharging: ASignal<bool?>(null, debugLabel: "t1dPhoneCharging"),
  };

  final Map<PropertiesDataName, ASignal<int?>> _intSignals = {
    PropertiesDataName.t1dPhoneBattery: ASignal<int?>(null, debugLabel: "t1dPhoneBattery"),
  };

  final Map<PropertiesDataName, ASignal<DateTime?>> _dateTimeSignals = {
    PropertiesDataName.cage: ASignal<DateTime?>(null, debugLabel: "CannulaAge"),
    PropertiesDataName.sage: ASignal<DateTime?>(null, debugLabel: "SensorAge"),
  };
  // Getters

  List<ASignal> allSignals() {
    return [
      ..._doubleSignals.values,
      ..._boolSignals.values,
      ..._intSignals.values,
      ..._dateTimeSignals.values,
    ];
  }

  // Double methods
  double? get iob => _doubleSignals[PropertiesDataName.iob]!.value;
  set iob(double? value) {
    _doubleSignals[PropertiesDataName.iob]!.value = value;
  }

  int get iobMinsOld {
    return _doubleSignals[PropertiesDataName.iob]!.lastSetAgo.inMinutes;
  }

  double? get basaliob => _doubleSignals[PropertiesDataName.basaliob]!.value;
  set basaliob(double? value) {
    _doubleSignals[PropertiesDataName.basaliob]!.value = value;
  }

  double? get treatmentiob => _doubleSignals[PropertiesDataName.treatmentiob]!.value;
  set treatmentiob(double? value) {
    _doubleSignals[PropertiesDataName.treatmentiob]!.value = value;
  }

  double? get cob => _doubleSignals[PropertiesDataName.cob]!.value;
  set cob(double? value) {
    _doubleSignals[PropertiesDataName.cob]!.value = value;
  }

  int get cobMinsOld {
    return _doubleSignals[PropertiesDataName.cob]!.lastSetAgo.inMinutes;
  }

  double? get reservoir => _doubleSignals[PropertiesDataName.reservoir]!.value;
  set reservoir(double? value) {
    _doubleSignals[PropertiesDataName.reservoir]!.value = value;
  }

  // Int methods
  int? get t1dPhoneBattery => _intSignals[PropertiesDataName.t1dPhoneBattery]!.value;
  set t1dPhoneBattery(int? value) {
    _intSignals[PropertiesDataName.t1dPhoneBattery]!.value = value;
  }

  // Bool methods
  bool? get t1dPhoneCharging => _boolSignals[PropertiesDataName.t1dPhoneCharging]!.value;
  set t1dPhoneCharging(bool? value) {
    _boolSignals[PropertiesDataName.t1dPhoneCharging]!.value = value;
  }

  // DateTime methods
  DateTime? get cage => _dateTimeSignals[PropertiesDataName.cage]!.value;
  set cage(DateTime? value) {
    _dateTimeSignals[PropertiesDataName.cage]!.value = value;
  }

  DateTime? get sage => _dateTimeSignals[PropertiesDataName.sage]!.value;
  set sage(DateTime? value) {
    _dateTimeSignals[PropertiesDataName.sage]!.value = value;
  }

  // Vis methods

  String get t1dPhoneChargingStr {
    var t1dPhonesCharging = PropertiesData().t1dPhoneCharging;
    if (t1dPhonesCharging == null) {
      return "?";
    }
    return t1dPhonesCharging ? "Charging" : "Not Charging";
  }

  String get t1dPhonesBatteryStr {
    int? t1dBattery = PropertiesData().t1dPhoneBattery;
    if (t1dBattery == null) {
      return "?";
    }
    return "$t1dBattery%";
  }
}
