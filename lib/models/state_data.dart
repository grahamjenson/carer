import 'package:carer/sql/carer_db.dart';
import 'package:carer/sql/key_value_store.dart';

enum StateDataName {
  summaryIOB,
  summaryCOB,
  summaryBWP,
  summaryCAge,
  summaryIAge,
  summaryBAge,
  summaryBattery,
}

class StateData extends KeyValueStore {
  static final Future<StateData> _instance = _createInstance();
  static Future<StateData> get instance => _instance;

  StateData(super.db);

  // Constructor
  static Future<StateData> _createInstance() async {
    final db = (await CarerDB.instance).db;
    var stateDB = StateData(db);
    await stateDB.internalPopulate();
    return stateDB;
  }

  double iob() {
    return getDouble(StateDataName.summaryIOB.name) ?? 0;
  }

  double cob() {
    return getDouble(StateDataName.summaryCOB.name) ?? 0;
  }

  double cage() {
    return getDouble(StateDataName.summaryCAge.name) ?? 0;
  }

  double battery() {
    return getDouble(StateDataName.summaryBattery.name) ?? 0;
  }

  Future<bool> setIOB(double iob) {
    return setDouble(StateDataName.summaryIOB.name, iob);
  }

  Future<bool> setCOB(double cob) {
    return setDouble(StateDataName.summaryCOB.name, cob);
  }

  Future<bool> setCAge(double bwp) {
    return setDouble(StateDataName.summaryCAge.name, bwp);
  }

  Future<bool> setBattery(double battery) {
    return setDouble(StateDataName.summaryBattery.name, battery);
  }
}
