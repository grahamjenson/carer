import 'package:carer/sql/key_value_store.dart';
import 'package:signals/signals_flutter.dart';

enum _AlarmNames {
  disableAlarms,
  testAlarmPlaying,
  alarmAsset,

  urgentLowAlarm,
  lowAlarm,
  lowMinutes,
  highAlarm,
  highMinutes,
  urgentHighAlarm,

  fastDropAlarm,
  fastDropAlarmMinutes,
  fastDropDelta,

  fastRiseAlarm,
  fastRiseAlarmMinutes,
  fastRiseDelta,

  noDataAlarmMinutes,

  lowPredictionAlarm,
  lowPredictionMinutes,
  smartSnooze,

  volumeOveride,
  volumeOverrideValue,
  volumeProgressionSeconds,
}

class AlarmSettings {
  static final AlarmSettings _singleton = AlarmSettings._();
  factory AlarmSettings() => _singleton;

  final Map<_AlarmNames, Signal> _signals = {
    _AlarmNames.disableAlarms: Signal<bool>(true, debugLabel: 'disableAlarms'),
    _AlarmNames.urgentLowAlarm:
        Signal<bool>(false, debugLabel: 'urgentLowAlarm'),
    _AlarmNames.lowAlarm: Signal<bool>(false, debugLabel: 'lowAlarm'),
    _AlarmNames.lowMinutes: Signal<int>(5, debugLabel: 'lowMinutes'),
    _AlarmNames.highAlarm: Signal<bool>(false, debugLabel: 'highAlarm'),
    _AlarmNames.highMinutes: Signal<int>(5, debugLabel: 'highMinutes'),
    _AlarmNames.urgentHighAlarm:
        Signal<bool>(false, debugLabel: 'urgentHighAlarm'),
    _AlarmNames.fastDropAlarm: Signal<bool>(false, debugLabel: 'fastDropAlarm'),
    _AlarmNames.fastDropAlarmMinutes:
        Signal<int>(5, debugLabel: 'fastDropAlarmMinutes'),
    _AlarmNames.fastDropDelta: Signal<int>(9, debugLabel: 'fastDropDelta'),
    _AlarmNames.fastRiseAlarm: Signal<bool>(false, debugLabel: 'fastRiseAlarm'),
    _AlarmNames.fastRiseAlarmMinutes:
        Signal<int>(5, debugLabel: 'fastRiseAlarmMinutes'),
    _AlarmNames.fastRiseDelta: Signal<int>(-9, debugLabel: 'fastRiseDelta'),
    _AlarmNames.noDataAlarmMinutes:
        Signal<int>(5, debugLabel: 'noDataAlarmMinutes'),
    _AlarmNames.lowPredictionAlarm:
        Signal<bool>(false, debugLabel: 'lowPredictionAlarm'),
    _AlarmNames.lowPredictionMinutes:
        Signal<int>(5, debugLabel: 'lowPredictionMinutes'),
    _AlarmNames.smartSnooze: Signal<bool>(false, debugLabel: 'smartSnooze'),
    _AlarmNames.volumeOveride: Signal<bool>(false, debugLabel: 'volumeOveride'),
    _AlarmNames.volumeOverrideValue:
        Signal<int>(10, debugLabel: 'volumeOverrideValue'),
    _AlarmNames.volumeProgressionSeconds:
        Signal<int>(10, debugLabel: 'volumeProgressionSeconds'),
    _AlarmNames.testAlarmPlaying:
        Signal<bool>(false, debugLabel: 'testAlarmPlaying'),
    _AlarmNames.alarmAsset:
        Signal<AlarmSounds>(AlarmSounds.nightguard, debugLabel: 'alarmAsset'),
  };

  AlarmSettings._();

  bool get disableAlarms => _signals[_AlarmNames.disableAlarms]!.value as bool;
  set disableAlarms(bool value) =>
      _signals[_AlarmNames.disableAlarms]!.value = value;

  bool get urgentLowAlarm =>
      _signals[_AlarmNames.urgentLowAlarm]!.value as bool;
  set urgentLowAlarm(bool value) =>
      _signals[_AlarmNames.urgentLowAlarm]!.value = value;

  bool get lowAlarm => _signals[_AlarmNames.lowAlarm]!.value as bool;
  set lowAlarm(bool value) => _signals[_AlarmNames.lowAlarm]!.value = value;

  int get lowMinutes => _signals[_AlarmNames.lowMinutes]!.value as int;
  set lowMinutes(int value) =>
      minutesSet(_signals[_AlarmNames.lowMinutes]! as Signal<int>, value);

  bool get highAlarm => _signals[_AlarmNames.highAlarm]!.value as bool;
  set highAlarm(bool value) => _signals[_AlarmNames.highAlarm]!.value = value;

  int get highMinutes => _signals[_AlarmNames.highMinutes]!.value as int;
  set highMinutes(int value) =>
      minutesSet(_signals[_AlarmNames.highMinutes]! as Signal<int>, value);

  bool get urgentHighAlarm =>
      _signals[_AlarmNames.urgentHighAlarm]!.value as bool;
  set urgentHighAlarm(bool value) =>
      _signals[_AlarmNames.urgentHighAlarm]!.value = value;

  bool get lowPredictionAlarm =>
      _signals[_AlarmNames.lowPredictionAlarm]!.value as bool;
  set lowPredictionAlarm(bool value) =>
      _signals[_AlarmNames.lowPredictionAlarm]!.value = value;

  int get lowPredictionMinutes =>
      _signals[_AlarmNames.lowPredictionMinutes]!.value as int;
  set lowPredictionMinutes(int value) => minutesSet(
      _signals[_AlarmNames.lowPredictionMinutes]! as Signal<int>, value);

  bool get fastDropAlarm => _signals[_AlarmNames.fastDropAlarm]!.value as bool;
  bool get fastDropAlarmPeek =>
      _signals[_AlarmNames.fastDropAlarm]!.peek() as bool;

  set fastDropAlarm(bool value) =>
      _signals[_AlarmNames.fastDropAlarm]!.value = value;

  int get fastDropAlarmMinutes =>
      _signals[_AlarmNames.fastDropAlarmMinutes]!.value as int;
  set fastDropAlarmMinutes(int value) => minutesSet(
      _signals[_AlarmNames.fastDropAlarmMinutes]! as Signal<int>, value);

  int get fastDropDelta => _signals[_AlarmNames.fastDropDelta]!.value as int;
  int get fastDropDeltaPeek =>
      _signals[_AlarmNames.fastDropDelta]!.peek() as int;

  set fastDropDelta(int value) => fastDropDeltaSet(
      _signals[_AlarmNames.fastDropDelta]! as Signal<int>, value);

  bool get fastRiseAlarm => _signals[_AlarmNames.fastRiseAlarm]!.value as bool;
  bool get fastRiseAlarmPeek =>
      _signals[_AlarmNames.fastRiseAlarm]!.peek() as bool;
  set fastRiseAlarm(bool value) =>
      _signals[_AlarmNames.fastRiseAlarm]!.value = value;

  int get fastRiseAlarmMinutes =>
      _signals[_AlarmNames.fastRiseAlarmMinutes]!.value as int;
  set fastRiseAlarmMinutes(int value) => minutesSet(
      _signals[_AlarmNames.fastRiseAlarmMinutes]! as Signal<int>, value);

  int get fastRiseDelta => _signals[_AlarmNames.fastRiseDelta]!.value as int;
  int get fastRiseDeltaPeek =>
      _signals[_AlarmNames.fastRiseDelta]!.peek() as int;

  set fastRiseDelta(int value) => fastRiseDeltaSet(
      _signals[_AlarmNames.fastRiseDelta]! as Signal<int>, value);

  int get noDataAlarmMinutes =>
      _signals[_AlarmNames.noDataAlarmMinutes]!.value as int;
  set noDataAlarmMinutes(int value) => noDataAlarmSet(
      _signals[_AlarmNames.noDataAlarmMinutes]! as Signal<int>, value);

  bool get smartSnooze => _signals[_AlarmNames.smartSnooze]!.value as bool;
  set smartSnooze(bool value) =>
      _signals[_AlarmNames.smartSnooze]!.value = value;

  bool get volumeOveride => _signals[_AlarmNames.volumeOveride]!.value as bool;
  set volumeOveride(bool value) =>
      _signals[_AlarmNames.volumeOveride]!.value = value;

  int get volumeOverrideValue =>
      _signals[_AlarmNames.volumeOverrideValue]!.value as int;
  int get volumeOverrideValuePeek =>
      _signals[_AlarmNames.volumeOverrideValue]!.peek() as int;

  set volumeOverrideValue(int value) => volumeOverrideValueSet(
      _signals[_AlarmNames.volumeOverrideValue]! as Signal<int>, value);

  int get volumeProgressionSeconds =>
      _signals[_AlarmNames.volumeProgressionSeconds]!.value as int;
  set volumeProgressionSeconds(int value) => volumeProgressionSecondsSet(
      _signals[_AlarmNames.volumeProgressionSeconds]! as Signal<int>, value);

  bool get testAlarmPlaying =>
      _signals[_AlarmNames.testAlarmPlaying]!.value as bool;
  set testAlarmPlaying(bool value) =>
      _signals[_AlarmNames.testAlarmPlaying]!.value = value;

  AlarmSounds get alarmAsset =>
      _signals[_AlarmNames.alarmAsset]!.value as AlarmSounds;
  set alarmAsset(AlarmSounds value) =>
      _signals[_AlarmNames.alarmAsset]!.value = value;

  allValues() {
    for (var signal in _signals.values) {
      var _ = signal.value;
    }
  }

  minutesSet(Signal<int> signal, value) {
    var validValues = [0, 5, 10, 15, 20, 30, 45, 60];
    if (!validValues.contains(value)) {
      return false;
    }
    signal.value = value;
  }

  noDataAlarmSet(Signal<int> signal, value) {
    var validValues = [-1, 10, 20, 30];
    if (!validValues.contains(value)) {
      return false;
    }
    signal.value = value;
  }

  volumeOverrideValueSet(Signal<int> signal, value) {
    if (value < 0) {
      value = 0;
    } else if (value > 100) {
      value = 100;
    }
    signal.value = value;
  }

  volumeProgressionSecondsSet(Signal<int> signal, value) {
    var validValues = [-1, 10, 20, 30, 60, 120];
    if (!validValues.contains(value)) {
      return false;
    }
    signal.value = value;
  }

  fastDropDeltaSet(Signal<int> signal, value) {
    if (value > 8) {
      value = 8;
    }
    signal.value = value;
  }

  fastRiseDeltaSet(Signal<int> signal, value) {
    if (value < -8) {
      value = -8;
    }
    signal.value = value;
  }

  setupDBPropagation() async {
    var prefs = await KeyValueStore.instance;

    disableAlarms =
        prefs.getBool(_AlarmNames.disableAlarms.name, defaultValue: false)!;
    urgentLowAlarm =
        prefs.getBool(_AlarmNames.urgentLowAlarm.name, defaultValue: false)!;
    lowAlarm = prefs.getBool(_AlarmNames.lowAlarm.name, defaultValue: false)!;
    highAlarm = prefs.getBool(_AlarmNames.highAlarm.name, defaultValue: false)!;
    lowMinutes = prefs.getInt(_AlarmNames.lowMinutes.name, defaultValue: 30)!;
    highMinutes = prefs.getInt(_AlarmNames.highMinutes.name, defaultValue: 30)!;
    urgentHighAlarm =
        prefs.getBool(_AlarmNames.urgentHighAlarm.name, defaultValue: false)!;
    lowPredictionAlarm = prefs.getBool(_AlarmNames.lowPredictionAlarm.name,
        defaultValue: false)!;
    lowPredictionMinutes =
        prefs.getInt(_AlarmNames.lowPredictionMinutes.name, defaultValue: 30)!;
    fastDropAlarm =
        prefs.getBool(_AlarmNames.fastDropAlarm.name, defaultValue: false)!;
    fastDropAlarmMinutes =
        prefs.getInt(_AlarmNames.fastDropAlarmMinutes.name, defaultValue: 30)!;
    fastDropDelta =
        prefs.getInt(_AlarmNames.fastDropDelta.name, defaultValue: -20)!;
    fastRiseAlarm =
        prefs.getBool(_AlarmNames.fastRiseAlarm.name, defaultValue: false)!;
    fastRiseAlarmMinutes =
        prefs.getInt(_AlarmNames.fastRiseAlarmMinutes.name, defaultValue: 30)!;
    fastRiseDelta =
        prefs.getInt(_AlarmNames.fastRiseDelta.name, defaultValue: 20)!;
    noDataAlarmMinutes =
        prefs.getInt(_AlarmNames.noDataAlarmMinutes.name, defaultValue: 30)!;
    smartSnooze =
        prefs.getBool(_AlarmNames.smartSnooze.name, defaultValue: false)!;
    volumeOveride =
        prefs.getBool(_AlarmNames.volumeOveride.name, defaultValue: false)!;
    volumeOverrideValue =
        prefs.getInt(_AlarmNames.volumeOverrideValue.name, defaultValue: 50)!;
    volumeProgressionSeconds = prefs
        .getInt(_AlarmNames.volumeProgressionSeconds.name, defaultValue: 10)!;

    var prefsAlarmAsset = prefs.getString(_AlarmNames.alarmAsset.name,
        defaultValue: AlarmSounds.nightguard.name)!;
    AlarmSounds.values.firstWhere((e) => e.name == prefsAlarmAsset,
        orElse: () => AlarmSounds.nightguard);

    effect(() => prefs.setBool(_AlarmNames.disableAlarms.name, disableAlarms));

    effect(
        () => prefs.setBool(_AlarmNames.urgentLowAlarm.name, urgentLowAlarm));

    effect(() => prefs.setBool(_AlarmNames.lowAlarm.name, lowAlarm));

    effect(() => prefs.setInt(_AlarmNames.lowMinutes.name, lowMinutes));

    effect(() => prefs.setBool(_AlarmNames.highAlarm.name, highAlarm));

    effect(() => prefs.setInt(_AlarmNames.highMinutes.name, highMinutes));

    effect(
        () => prefs.setBool(_AlarmNames.urgentHighAlarm.name, urgentHighAlarm));

    effect(() => prefs.setBool(_AlarmNames.fastDropAlarm.name, fastDropAlarm));

    effect(() => prefs.setInt(
        _AlarmNames.fastDropAlarmMinutes.name, fastDropAlarmMinutes));

    effect(() => prefs.setInt(_AlarmNames.fastDropDelta.name, fastDropDelta));

    effect(() => prefs.setBool(_AlarmNames.fastRiseAlarm.name, fastRiseAlarm));

    effect(() => prefs.setInt(
        _AlarmNames.fastRiseAlarmMinutes.name, fastRiseAlarmMinutes));

    effect(() => prefs.setInt(_AlarmNames.fastRiseDelta.name, fastRiseDelta));

    effect(() =>
        prefs.setInt(_AlarmNames.noDataAlarmMinutes.name, noDataAlarmMinutes));

    effect(() =>
        prefs.setBool(_AlarmNames.lowPredictionAlarm.name, lowPredictionAlarm));

    effect(() => prefs.setInt(
        _AlarmNames.lowPredictionMinutes.name, lowPredictionMinutes));

    effect(() => prefs.setBool(_AlarmNames.smartSnooze.name, smartSnooze));

    effect(() => prefs.setBool(_AlarmNames.volumeOveride.name, volumeOveride));

    effect(() => prefs.setInt(
        _AlarmNames.volumeOverrideValue.name, volumeOverrideValue));

    effect(() => prefs.setInt(
        _AlarmNames.volumeProgressionSeconds.name, volumeProgressionSeconds));

    effect(() {
      var value = (alarmAsset).name;
      prefs.setString(_AlarmNames.alarmAsset.name, value);
    });
  }
}

enum AlarmSounds { nightguard, letsgo, hybridas }

extension AlarmSoundsExtension on AlarmSounds {
  String get name {
    switch (this) {
      case AlarmSounds.nightguard:
        return 'Nightguard';
      case AlarmSounds.letsgo:
        return 'Lets Go';
      case AlarmSounds.hybridas:
        return 'Hybridas';
      default:
        return 'Nightguard';
    }
  }

  String get asset {
    switch (this) {
      case AlarmSounds.nightguard:
        return 'alarm.mp3';
      case AlarmSounds.letsgo:
        return 'letsgo.mp3';
      case AlarmSounds.hybridas:
        return 'hybridas.mp3';
      default:
        return 'alarm.mp3';
    }
  }
}
