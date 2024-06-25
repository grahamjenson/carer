import 'package:carer/sql/carer_db.dart';
import 'package:carer/sql/key_value_store.dart';
import 'package:signals/signals_flutter.dart';

enum StateDataName {
  summaryIOB,
  summaryCOB,
  summaryCAge,
  summaryBattery,
}

class StateData {
  static final StateData _singleton = StateData._();
  factory StateData() => _singleton;

  final Map<StateDataName, Signal> _signals = {
    StateDataName.summaryIOB: Signal<double>(0.0, debugLabel: 'summaryIOB'),
    StateDataName.summaryCOB: Signal<double>(0.0, debugLabel: 'summaryCOB'),
    StateDataName.summaryCAge: Signal<double>(0.0, debugLabel: 'summaryCAge'),
    StateDataName.summaryBattery: Signal<double>(0.0, debugLabel: 'summaryBattery'),
  };

  StateData._();

  // Constructor
  setupDBPropagation() async {
    final db = (await CarerDB.instance).db;
    var kvdb = KeyValueStore(db);
    await kvdb.internalPopulate();

    effect(() {
      kvdb.setDouble(StateDataName.summaryBattery.name, _signals[StateDataName.summaryBattery]!.value);
    });

    effect(() {
      kvdb.setDouble(StateDataName.summaryCOB.name, _signals[StateDataName.summaryCOB]!.value);
    });

    effect(() {
      kvdb.setDouble(StateDataName.summaryIOB.name, _signals[StateDataName.summaryIOB]!.value);
    });

    effect(() {
      kvdb.setDouble(StateDataName.summaryCAge.name, _signals[StateDataName.summaryCAge]!.value);
    });
  }

  double iob() {
    return _signals[StateDataName.summaryIOB]!.value;
  }

  double cob() {
    return _signals[StateDataName.summaryCOB]!.value;
  }

  double cage() {
    return _signals[StateDataName.summaryCAge]!.value;
  }

  double battery() {
    return _signals[StateDataName.summaryBattery]!.value;
  }

  setIOB(double iob) {
    _signals[StateDataName.summaryIOB]!.value = iob;
  }

  setCOB(double cob) {
    _signals[StateDataName.summaryCOB]!.value = cob;
  }

  setCAge(double cage) {
    _signals[StateDataName.summaryCAge]!.value = cage;
  }

  setBattery(double battery) {
    _signals[StateDataName.summaryBattery]!.value = battery;
  }
}
