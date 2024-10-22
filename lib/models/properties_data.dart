import 'package:carer/sql/carer_db.dart';
import 'package:carer/sql/key_value_store.dart';
import 'package:carer/utils/futures.dart';

enum PropertiesDataName {
  battery,
  isCharging,
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

  final Map<PropertiesDataName, ASignal> _signals = {
    PropertiesDataName.battery: ASignal(100.0, debugLabel: "Battery"),
    PropertiesDataName.isCharging: ASignal(false, debugLabel: "isCharging"),
    PropertiesDataName.iob: ASignal(0.0, debugLabel: "IOB"),
    PropertiesDataName.basaliob: ASignal(0.0, debugLabel: "BasalIOB"),
    PropertiesDataName.treatmentiob: ASignal(0.0, debugLabel: "TreatmentiOB"),
    PropertiesDataName.cob: ASignal(0.0, debugLabel: "COB"),
    PropertiesDataName.cage: ASignal(0.0, debugLabel: "CannulaAge"),
    PropertiesDataName.sage: ASignal(0.0, debugLabel: "SensorAge"),
    PropertiesDataName.reservoir: ASignal(0.0, debugLabel: "Reservoir"),
  };

  // Constructor
  Future<bool> setupDBPropagation() async {
    final db = (await CarerDB.instance).db;
    var kvdb = KeyValueStore(db);
    await kvdb.internalPopulate();

    battery = kvdb.getDouble(PropertiesDataName.battery.name, defaultValue: 100.0)!;
    isCharging = kvdb.getBool(PropertiesDataName.isCharging.name, defaultValue: false)!;
    iob = kvdb.getDouble(PropertiesDataName.iob.name, defaultValue: 0.0)!;
    basaliob = kvdb.getDouble(PropertiesDataName.basaliob.name, defaultValue: 0.0)!;
    treatmentiob = kvdb.getDouble(PropertiesDataName.treatmentiob.name, defaultValue: 0.0)!;
    cob = kvdb.getDouble(PropertiesDataName.cob.name, defaultValue: 0.0)!;
    cage = DateTime.fromMillisecondsSinceEpoch(kvdb.getDouble(PropertiesDataName.cage.name, defaultValue: 0.0)!.toInt());
    sage = DateTime.fromMillisecondsSinceEpoch(kvdb.getDouble(PropertiesDataName.sage.name, defaultValue: 0.0)!.toInt());
    reservoir = kvdb.getDouble(PropertiesDataName.reservoir.name, defaultValue: 0.0)!;

    aeffect(
      () {
        kvdb.setDouble(PropertiesDataName.battery.name, _signals[PropertiesDataName.battery]!.value);
      },
      debugLabel: "Battery",
    );

    aeffect(
      () {
        kvdb.setBool(PropertiesDataName.isCharging.name, _signals[PropertiesDataName.isCharging]!.value);
      },
      debugLabel: "isCharging",
    );

    aeffect(
      () {
        kvdb.setDouble(PropertiesDataName.iob.name, _signals[PropertiesDataName.iob]!.value);
      },
      debugLabel: "IOB",
    );

    aeffect(
      () {
        kvdb.setDouble(PropertiesDataName.basaliob.name, _signals[PropertiesDataName.basaliob]!.value);
      },
      debugLabel: "BasalIOB",
    );

    aeffect(
      () {
        kvdb.setDouble(PropertiesDataName.treatmentiob.name, _signals[PropertiesDataName.treatmentiob]!.value);
      },
      debugLabel: "TreatmentiOB",
    );

    aeffect(
      () {
        kvdb.setDouble(PropertiesDataName.cob.name, _signals[PropertiesDataName.cob]!.value);
      },
      debugLabel: "COB",
    );

    aeffect(
      () {
        kvdb.setDouble(PropertiesDataName.cage.name, _signals[PropertiesDataName.cage]!.value);
      },
      debugLabel: "CAGE",
    );

    aeffect(
      () {
        kvdb.setDouble(PropertiesDataName.sage.name, _signals[PropertiesDataName.sage]!.value);
      },
      debugLabel: "SAGE",
    );

    aeffect(
      () {
        kvdb.setDouble(PropertiesDataName.reservoir.name, _signals[PropertiesDataName.reservoir]!.value);
      },
      debugLabel: "Reservoir",
    );

    return true;
  }

  // Getters

  bool t1dPhoneIsCharging() => _signals[PropertiesDataName.isCharging]!.value;
  int t1dPhonesBatteryLevel() => battery.toInt();

  double get battery => _signals[PropertiesDataName.battery]!.value;
  double get iob => _signals[PropertiesDataName.iob]!.value;
  double get basaliob => _signals[PropertiesDataName.basaliob]!.value;
  double get treatmentiob => _signals[PropertiesDataName.treatmentiob]!.value;
  double get cob => _signals[PropertiesDataName.cob]!.value;
  DateTime get cage => DateTime.fromMillisecondsSinceEpoch(_signals[PropertiesDataName.cage]!.value.toInt());
  DateTime get sage => DateTime.fromMillisecondsSinceEpoch(_signals[PropertiesDataName.sage]!.value.toInt());
  double get reservoir => _signals[PropertiesDataName.reservoir]!.value;

  set battery(double value) {
    _signals[PropertiesDataName.battery]!.value = value;
  }

  set isCharging(bool value) {
    _signals[PropertiesDataName.isCharging]!.value = value;
  }

  set iob(double value) {
    _signals[PropertiesDataName.iob]!.value = value;
  }

  set basaliob(double value) {
    _signals[PropertiesDataName.basaliob]!.value = value;
  }

  set treatmentiob(double value) {
    _signals[PropertiesDataName.treatmentiob]!.value = value;
  }

  set cob(double value) {
    _signals[PropertiesDataName.cob]!.value = value;
  }

  set cage(DateTime value) {
    _signals[PropertiesDataName.cage]!.value = value.millisecondsSinceEpoch.toDouble();
  }

  set sage(DateTime value) {
    _signals[PropertiesDataName.sage]!.value = value.millisecondsSinceEpoch.toDouble();
  }

  set reservoir(double value) {
    _signals[PropertiesDataName.reservoir]!.value = value;
  }
}
