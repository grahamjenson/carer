import 'package:carer/sql/key_value_store.dart';
import 'package:carer/utils/futures.dart';

enum _AlarmNames {
  disableAlarms,

  urgentLowAlarm,
  lowAlarm,
  lowMinutes,
  highAlarm,
  highMinutes,
  urgentHighAlarm,

  fastDropAlarm,
  fastDropAlarmMinutes,

  fastRiseAlarm,
  fastRiseAlarmMinutes,

  noDataAlarmMinutes,

  lowPredictionAlarm,
  lowPredictionMinutes,

  carerBatteryAlarm,
  t1dBatteryAlarm,
}

class AlarmSettings {
  static final AlarmSettings _singleton = AlarmSettings._();
  factory AlarmSettings() => _singleton;

  final Map<_AlarmNames, ASignal> _signals = {
    _AlarmNames.disableAlarms: ASignal<bool>(true, debugLabel: 'disableAlarms'),
    _AlarmNames.urgentLowAlarm: ASignal<bool>(false, debugLabel: 'urgentLowAlarm'),
    _AlarmNames.lowAlarm: ASignal<bool>(false, debugLabel: 'lowAlarm'),
    _AlarmNames.lowMinutes: ASignal<int>(5, debugLabel: 'lowMinutes'),
    _AlarmNames.highAlarm: ASignal<bool>(false, debugLabel: 'highAlarm'),
    _AlarmNames.highMinutes: ASignal<int>(5, debugLabel: 'highMinutes'),
    _AlarmNames.urgentHighAlarm: ASignal<bool>(false, debugLabel: 'urgentHighAlarm'),
    _AlarmNames.fastDropAlarm: ASignal<bool>(false, debugLabel: 'fastDropAlarm'),
    _AlarmNames.fastDropAlarmMinutes: ASignal<int>(5, debugLabel: 'fastDropAlarmMinutes'),
    _AlarmNames.fastRiseAlarm: ASignal<bool>(false, debugLabel: 'fastRiseAlarm'),
    _AlarmNames.fastRiseAlarmMinutes: ASignal<int>(5, debugLabel: 'fastRiseAlarmMinutes'),
    _AlarmNames.noDataAlarmMinutes: ASignal<int>(-1, debugLabel: 'noDataAlarmMinutes'),
    _AlarmNames.lowPredictionAlarm: ASignal<bool>(false, debugLabel: 'lowPredictionAlarm'),
    _AlarmNames.lowPredictionMinutes: ASignal<int>(5, debugLabel: 'lowPredictionMinutes'),
    _AlarmNames.carerBatteryAlarm: ASignal<bool>(false, debugLabel: 'carerBatteryAlarm'),
    _AlarmNames.t1dBatteryAlarm: ASignal<bool>(false, debugLabel: 't1dBatteryAlarm'),
  };

  AlarmSettings._();

  bool get disableAlarms => _signals[_AlarmNames.disableAlarms]!.value as bool;
  set disableAlarms(bool value) => _signals[_AlarmNames.disableAlarms]!.value = value;

  bool get urgentLowAlarm => _signals[_AlarmNames.urgentLowAlarm]!.value as bool;
  set urgentLowAlarm(bool value) => _signals[_AlarmNames.urgentLowAlarm]!.value = value;

  bool get lowAlarm => _signals[_AlarmNames.lowAlarm]!.value as bool;
  set lowAlarm(bool value) => _signals[_AlarmNames.lowAlarm]!.value = value;

  int get lowMinutes => _signals[_AlarmNames.lowMinutes]!.value as int;
  set lowMinutes(int value) => minutesSet(_signals[_AlarmNames.lowMinutes]! as ASignal<int>, value);

  bool get highAlarm => _signals[_AlarmNames.highAlarm]!.value as bool;
  set highAlarm(bool value) => _signals[_AlarmNames.highAlarm]!.value = value;

  int get highMinutes => _signals[_AlarmNames.highMinutes]!.value as int;
  set highMinutes(int value) => minutesSet(_signals[_AlarmNames.highMinutes]! as ASignal<int>, value);

  bool get urgentHighAlarm => _signals[_AlarmNames.urgentHighAlarm]!.value as bool;
  set urgentHighAlarm(bool value) => _signals[_AlarmNames.urgentHighAlarm]!.value = value;

  bool get lowPredictionAlarm => _signals[_AlarmNames.lowPredictionAlarm]!.value as bool;
  set lowPredictionAlarm(bool value) => _signals[_AlarmNames.lowPredictionAlarm]!.value = value;

  int get lowPredictionMinutes => _signals[_AlarmNames.lowPredictionMinutes]!.value as int;
  set lowPredictionMinutes(int value) => minutesSet(_signals[_AlarmNames.lowPredictionMinutes]! as ASignal<int>, value);

  bool get fastDropAlarm => _signals[_AlarmNames.fastDropAlarm]!.value as bool;
  bool get fastDropAlarmPeek => _signals[_AlarmNames.fastDropAlarm]!.peek() as bool;

  set fastDropAlarm(bool value) => _signals[_AlarmNames.fastDropAlarm]!.value = value;

  int get fastDropAlarmMinutes => _signals[_AlarmNames.fastDropAlarmMinutes]!.value as int;
  set fastDropAlarmMinutes(int value) => minutesSet(_signals[_AlarmNames.fastDropAlarmMinutes]! as ASignal<int>, value);

  bool get fastRiseAlarm => _signals[_AlarmNames.fastRiseAlarm]!.value as bool;
  bool get fastRiseAlarmPeek => _signals[_AlarmNames.fastRiseAlarm]!.peek() as bool;
  set fastRiseAlarm(bool value) => _signals[_AlarmNames.fastRiseAlarm]!.value = value;

  int get fastRiseAlarmMinutes => _signals[_AlarmNames.fastRiseAlarmMinutes]!.value as int;
  set fastRiseAlarmMinutes(int value) => minutesSet(_signals[_AlarmNames.fastRiseAlarmMinutes]! as ASignal<int>, value);

  int get noDataAlarmMinutes => _signals[_AlarmNames.noDataAlarmMinutes]!.value as int;
  set noDataAlarmMinutes(int value) => noDataAlarmSet(_signals[_AlarmNames.noDataAlarmMinutes]! as ASignal<int>, value);

  bool get carerBatteryAlarm => _signals[_AlarmNames.carerBatteryAlarm]!.value as bool;
  set carerBatteryAlarm(bool value) => _signals[_AlarmNames.carerBatteryAlarm]!.value = value;

  bool get t1dBatteryAlarm => _signals[_AlarmNames.t1dBatteryAlarm]!.value as bool;
  set t1dBatteryAlarm(bool value) => _signals[_AlarmNames.t1dBatteryAlarm]!.value = value;

  allValues() {
    for (var signal in _signals.values) {
      var _ = signal.value;
    }
  }

  List<ASignal> allSignals() {
    return _signals.values.toList();
  }

  minutesSet(ASignal<int> signal, value) {
    var validValues = [0, 5, 10, 15, 20, 30, 40, 45, 60];
    if (!validValues.contains(value)) {
      return false;
    }
    signal.value = value;
  }

  noDataAlarmSet(ASignal<int> signal, value) {
    var validValues = [-1, 10, 20, 30];
    if (!validValues.contains(value)) {
      return false;
    }
    signal.value = value;
  }

  volumeOverrideValueSet(ASignal<int> signal, value) {
    if (value < 0) {
      value = 0;
    } else if (value > 100) {
      value = 100;
    }
    signal.value = value;
  }

  volumeProgressionSecondsSet(ASignal<int> signal, value) {
    var validValues = [-1, 10, 20, 30, 60, 120];
    if (!validValues.contains(value)) {
      return false;
    }
    signal.value = value;
  }

  setupDBPropagation(KeyValueStore prefs) {
    disableAlarms = prefs.getBool(_AlarmNames.disableAlarms.name, defaultValue: false)!;
    urgentLowAlarm = prefs.getBool(_AlarmNames.urgentLowAlarm.name, defaultValue: false)!;
    lowAlarm = prefs.getBool(_AlarmNames.lowAlarm.name, defaultValue: false)!;
    highAlarm = prefs.getBool(_AlarmNames.highAlarm.name, defaultValue: false)!;
    lowMinutes = prefs.getInt(_AlarmNames.lowMinutes.name, defaultValue: 30)!;
    highMinutes = prefs.getInt(_AlarmNames.highMinutes.name, defaultValue: 30)!;
    urgentHighAlarm = prefs.getBool(_AlarmNames.urgentHighAlarm.name, defaultValue: false)!;
    lowPredictionAlarm = prefs.getBool(_AlarmNames.lowPredictionAlarm.name, defaultValue: false)!;
    lowPredictionMinutes = prefs.getInt(_AlarmNames.lowPredictionMinutes.name, defaultValue: 30)!;
    fastDropAlarm = prefs.getBool(_AlarmNames.fastDropAlarm.name, defaultValue: false)!;
    fastDropAlarmMinutes = prefs.getInt(_AlarmNames.fastDropAlarmMinutes.name, defaultValue: 30)!;

    fastRiseAlarm = prefs.getBool(_AlarmNames.fastRiseAlarm.name, defaultValue: false)!;
    fastRiseAlarmMinutes = prefs.getInt(_AlarmNames.fastRiseAlarmMinutes.name, defaultValue: 30)!;

    noDataAlarmMinutes = prefs.getInt(_AlarmNames.noDataAlarmMinutes.name, defaultValue: 30)!;

    // Turn off alarms
    aeffect(() => prefs.setBool(_AlarmNames.disableAlarms.name, disableAlarms));

    // Target Alarms
    aeffect(() => prefs.setBool(_AlarmNames.urgentLowAlarm.name, urgentLowAlarm));

    aeffect(() => prefs.setBool(_AlarmNames.lowAlarm.name, lowAlarm));

    aeffect(() => prefs.setInt(_AlarmNames.lowMinutes.name, lowMinutes));

    aeffect(() => prefs.setBool(_AlarmNames.highAlarm.name, highAlarm));

    aeffect(() => prefs.setInt(_AlarmNames.highMinutes.name, highMinutes));

    aeffect(() => prefs.setBool(_AlarmNames.urgentHighAlarm.name, urgentHighAlarm));

    // Diff alarms
    aeffect(() => prefs.setBool(_AlarmNames.fastDropAlarm.name, fastDropAlarm));

    aeffect(() => prefs.setInt(_AlarmNames.fastDropAlarmMinutes.name, fastDropAlarmMinutes));

    aeffect(() => prefs.setBool(_AlarmNames.fastRiseAlarm.name, fastRiseAlarm));

    aeffect(() => prefs.setInt(_AlarmNames.fastRiseAlarmMinutes.name, fastRiseAlarmMinutes));

    // No data alarms
    aeffect(() => prefs.setInt(_AlarmNames.noDataAlarmMinutes.name, noDataAlarmMinutes));

    // Prediction alarms
    aeffect(() => prefs.setBool(_AlarmNames.lowPredictionAlarm.name, lowPredictionAlarm));

    aeffect(() => prefs.setInt(_AlarmNames.lowPredictionMinutes.name, lowPredictionMinutes));

    // Battery alarms
    aeffect(() => prefs.setBool(_AlarmNames.carerBatteryAlarm.name, carerBatteryAlarm));

    aeffect(() => prefs.setBool(_AlarmNames.t1dBatteryAlarm.name, t1dBatteryAlarm));
  }
}
