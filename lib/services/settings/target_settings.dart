import 'package:carer/sql/key_value_store.dart';
import 'package:signals/signals.dart';

// find where in the target range and by what proportion a number is
// returns a tuple of (Targets, proportion)

enum _TNames {
  targetHigh,
  targetLow,
  urgentHigh,
  urgentLow,
  fastDropDelta,
  fastRiseDelta,
}

class TargetSettings {
  static final TargetSettings _singleton = TargetSettings._();
  factory TargetSettings() => _singleton;

  final Map<_TNames, Signal<int>> _signals = {
    _TNames.targetHigh: Signal<int>(180, debugLabel: 'targetHigh'),
    _TNames.targetLow: Signal<int>(72, debugLabel: 'targetLow'),
    _TNames.urgentHigh: Signal<int>(270, debugLabel: 'urgentHigh'),
    _TNames.urgentLow: Signal<int>(55, debugLabel: 'urgentLow'),
    _TNames.fastDropDelta: Signal<int>(9, debugLabel: 'fastDropDelta'),
    _TNames.fastRiseDelta: Signal<int>(-9, debugLabel: 'fastRiseDelta'),
  };

  TargetSettings._();

  allValues() {
    for (var signal in _signals.values) {
      var _ = signal.value;
    }
  }

  int get targetHigh => _signals[_TNames.targetHigh]!.value;
  int get targetHighPeek => _signals[_TNames.targetHigh]!.peek();
  set targetHigh(int value) {
    if (!validTargets(urgentLow, targetLow, value, urgentHigh)) {
      return;
    }
    _signals[_TNames.targetHigh]!.value = value;
  }

  int get targetLow => _signals[_TNames.targetLow]!.value;
  int get targetLowPeek => _signals[_TNames.targetLow]!.peek();

  set targetLow(int value) {
    if (!validTargets(urgentLow, value, targetHigh, urgentHigh)) {
      return;
    }
    _signals[_TNames.targetLow]!.value = value;
  }

  int get urgentHigh => _signals[_TNames.urgentHigh]!.value;
  int get urgentHighPeek => _signals[_TNames.urgentHigh]!.peek();
  set urgentHigh(int value) {
    if (!validTargets(urgentLow, targetLow, targetHigh, value)) {
      return;
    }
    _signals[_TNames.urgentHigh]!.value = value;
  }

  int get urgentLow => _signals[_TNames.urgentLow]!.value;
  int get urgentLowPeek => _signals[_TNames.urgentLow]!.peek();
  set urgentLow(int value) {
    if (!validTargets(value, targetLow, targetHigh, urgentHigh)) {
      return;
    }
    _signals[_TNames.urgentLow]!.value = value;
  }

  int get fastDropDelta => _signals[_TNames.fastDropDelta]!.value;
  int get fastDropDeltaPeek => _signals[_TNames.fastDropDelta]!.peek();

  set fastDropDelta(int value) => fastDropDeltaSet(_signals[_TNames.fastDropDelta]!, value);

  int get fastRiseDelta => _signals[_TNames.fastRiseDelta]!.value;
  int get fastRiseDeltaPeek => _signals[_TNames.fastRiseDelta]!.peek();

  set fastRiseDelta(int value) => fastRiseDeltaSet(_signals[_TNames.fastRiseDelta]!, value);

  bool validTargets(int urgentLow, int targetLow, int targetHigh, int urgentHigh) {
    return 9 <= urgentLow && urgentLow <= targetLow && targetLow <= targetHigh && targetHigh <= urgentHigh && urgentHigh <= 360;
  }

  fastDropDeltaSet(Signal<int> signal, value) {
    if (value > -8) {
      value = -8;
    }
    signal.value = value;
  }

  fastRiseDeltaSet(Signal<int> signal, value) {
    if (value < 8) {
      value = 8;
    }
    signal.value = value;
  }

  setupDBPropagation() async {
    var prefs = await KeyValueStore.instance;
    targetHigh = prefs.getInt(_TNames.targetHigh.name) ?? 180;
    targetLow = prefs.getInt(_TNames.targetLow.name) ?? 72;
    urgentHigh = prefs.getInt(_TNames.urgentHigh.name) ?? 270;
    urgentLow = prefs.getInt(_TNames.urgentLow.name) ?? 55;
    fastDropDelta = prefs.getInt(_TNames.fastDropDelta.name, defaultValue: -20)!;
    fastRiseDelta = prefs.getInt(_TNames.fastRiseDelta.name, defaultValue: 20)!;

    effect(() => prefs.setInt(_TNames.fastDropDelta.name, fastDropDelta));

    effect(() => prefs.setInt(_TNames.fastRiseDelta.name, fastRiseDelta));

    effect(() => prefs.setInt(_TNames.targetHigh.name, targetHigh));

    effect(() => prefs.setInt(_TNames.targetLow.name, targetLow));

    effect(() => prefs.setInt(_TNames.urgentHigh.name, urgentHigh));

    effect(() => prefs.setInt(_TNames.urgentLow.name, urgentLow));
  }
}
