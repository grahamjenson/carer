import 'package:carer/sql/carer_db.dart';
import 'package:carer/sql/key_value_store.dart';
import 'package:carer/utils/futures.dart';
import 'package:signals/signals_flutter.dart';

enum PropertiesDataName {
  battery,
  batteryDisplay,
  iob,
  basaliob,
  treatmentIob,
  cob,
  cage,
  sage,
}

class PropertiesData {
  static final PropertiesData _singleton = PropertiesData._();
  factory PropertiesData() => _singleton;
  PropertiesData._();

  final Map<PropertiesDataName, Signal> _signals = {
    PropertiesDataName.battery: Signal(100.0, debugLabel: "Battery"),
    PropertiesDataName.batteryDisplay: Signal("", debugLabel: "BatteryDisplay"),
    PropertiesDataName.iob: Signal(0.0, debugLabel: "IOB"),
    PropertiesDataName.basaliob: Signal(0.0, debugLabel: "BasalIOB"),
    PropertiesDataName.treatmentIob: Signal(0.0, debugLabel: "TreatmentIOB"),
    PropertiesDataName.cob: Signal(0.0, debugLabel: "COB"),
    PropertiesDataName.cage: Signal(0.0, debugLabel: "CannulaAge"),
    PropertiesDataName.sage: Signal(0.0, debugLabel: "SensorAge"),
  };

  // Constructor
  Future<bool> setupDBPropagation() async {
    final db = (await CarerDB.instance).db;
    var kvdb = KeyValueStore(db);
    await kvdb.internalPopulate();

    aeffect(() {
      kvdb.setDouble(PropertiesDataName.battery.name, _signals[PropertiesDataName.battery]!.value);
    });

    aeffect(() {
      kvdb.setString(PropertiesDataName.batteryDisplay.name, _signals[PropertiesDataName.batteryDisplay]!.value);
    });

    aeffect(() {
      kvdb.setDouble(PropertiesDataName.iob.name, _signals[PropertiesDataName.iob]!.value);
    });

    aeffect(() {
      kvdb.setDouble(PropertiesDataName.basaliob.name, _signals[PropertiesDataName.basaliob]!.value);
    });

    aeffect(() {
      kvdb.setDouble(PropertiesDataName.treatmentIob.name, _signals[PropertiesDataName.treatmentIob]!.value);
    });

    aeffect(() {
      kvdb.setDouble(PropertiesDataName.cob.name, _signals[PropertiesDataName.cob]!.value);
    });

    aeffect(() {
      kvdb.setDouble(PropertiesDataName.cage.name, _signals[PropertiesDataName.cage]!.value);
    });

    aeffect(() {
      kvdb.setDouble(PropertiesDataName.sage.name, _signals[PropertiesDataName.sage]!.value);
    });

    return true;
  }

  // Getters
  double get battery => _signals[PropertiesDataName.battery]!.value;
  String get batteryDisplay => _signals[PropertiesDataName.batteryDisplay]!.value;
  bool get isCharging => batteryDisplay.contains("⚡");

  double get iob => _signals[PropertiesDataName.iob]!.value;
  double get basaliob => _signals[PropertiesDataName.basaliob]!.value;
  double get treatmentIob => _signals[PropertiesDataName.treatmentIob]!.value;
  double get cob => _signals[PropertiesDataName.cob]!.value;
  DateTime get cage => DateTime.fromMillisecondsSinceEpoch(_signals[PropertiesDataName.cage]!.value.toInt());
  DateTime get sage => DateTime.fromMillisecondsSinceEpoch(_signals[PropertiesDataName.sage]!.value.toInt());

  setBattery(double value) {
    _signals[PropertiesDataName.battery]!.value = value;
  }

  setBatteryDisplay(String value) {
    _signals[PropertiesDataName.batteryDisplay]!.value = value;
  }

  setIOB(double value) {
    _signals[PropertiesDataName.iob]!.value = value;
  }

  setIOBBasal(double value) {
    _signals[PropertiesDataName.basaliob]!.value = value;
  }

  setIOBTreatment(double value) {
    _signals[PropertiesDataName.treatmentIob]!.value = value;
  }

  setCOB(double value) {
    _signals[PropertiesDataName.cob]!.value = value;
  }

  setCAge(double value) {
    _signals[PropertiesDataName.cage]!.value = value;
  }

  setSAge(double value) {
    _signals[PropertiesDataName.sage]!.value = value;
  }
}
