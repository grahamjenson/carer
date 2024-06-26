import 'package:carer/sql/key_value_store.dart';
import 'package:signals/signals.dart';

// find where in the target range and by what proportion a number is
// returns a tuple of (Targets, proportion)

enum _TNames {
  highTarget,
  lowTarget,
  highUrgent,
  lowUrgent,
  fastDropDelta,
  fastRiseDelta,
}

class TargetSettings {
  static final TargetSettings _singleton = TargetSettings._();
  factory TargetSettings() => _singleton;

  final Map<_TNames, Signal<int>> _signals = {
    _TNames.highTarget: Signal<int>(180, debugLabel: 'highTarget'),
    _TNames.lowTarget: Signal<int>(72, debugLabel: 'lowTarget'),
    _TNames.highUrgent: Signal<int>(270, debugLabel: 'highUrgent'),
    _TNames.lowUrgent: Signal<int>(55, debugLabel: 'lowUrgent'),
    _TNames.fastDropDelta: Signal<int>(9, debugLabel: 'fastDropDelta'),
    _TNames.fastRiseDelta: Signal<int>(-9, debugLabel: 'fastRiseDelta'),
  };

  TargetSettings._();

  allValues() {
    for (var signal in _signals.values) {
      var _ = signal.value;
    }
  }

  int get highTarget => _signals[_TNames.highTarget]!.value;
  int get highTargetPeek => _signals[_TNames.highTarget]!.peek();
  set highTarget(int value) {
    if (!validTargets(lowUrgent, lowTarget, value, highUrgent)) {
      return;
    }
    _signals[_TNames.highTarget]!.value = value;
  }

  int get lowTarget => _signals[_TNames.lowTarget]!.value;
  int get lowTargetPeek => _signals[_TNames.lowTarget]!.peek();

  set lowTarget(int value) {
    if (!validTargets(lowUrgent, value, highTarget, highUrgent)) {
      return;
    }
    _signals[_TNames.lowTarget]!.value = value;
  }

  int get highUrgent => _signals[_TNames.highUrgent]!.value;
  int get highUrgentPeek => _signals[_TNames.highUrgent]!.peek();
  set highUrgent(int value) {
    if (!validTargets(lowUrgent, lowTarget, highTarget, value)) {
      return;
    }
    _signals[_TNames.highUrgent]!.value = value;
  }

  int get lowUrgent => _signals[_TNames.lowUrgent]!.value;
  int get lowUrgentPeek => _signals[_TNames.lowUrgent]!.peek();
  set lowUrgent(int value) {
    if (!validTargets(value, lowTarget, highTarget, highUrgent)) {
      return;
    }
    _signals[_TNames.lowUrgent]!.value = value;
  }

  int get fastDropDelta => _signals[_TNames.fastDropDelta]!.value;
  int get fastDropDeltaPeek => _signals[_TNames.fastDropDelta]!.peek();

  set fastDropDelta(int value) => fastDropDeltaSet(_signals[_TNames.fastDropDelta]!, value);

  int get fastRiseDelta => _signals[_TNames.fastRiseDelta]!.value;
  int get fastRiseDeltaPeek => _signals[_TNames.fastRiseDelta]!.peek();

  set fastRiseDelta(int value) => fastRiseDeltaSet(_signals[_TNames.fastRiseDelta]!, value);

  bool validTargets(int lowUrgent, int lowTarget, int highTarget, int highUrgent) {
    return 9 <= lowUrgent && lowUrgent <= lowTarget && lowTarget <= highTarget && highTarget <= highUrgent && highUrgent <= 360;
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
    highTarget = prefs.getInt(_TNames.highTarget.name) ?? 180;
    lowTarget = prefs.getInt(_TNames.lowTarget.name) ?? 72;
    highUrgent = prefs.getInt(_TNames.highUrgent.name) ?? 270;
    lowUrgent = prefs.getInt(_TNames.lowUrgent.name) ?? 55;
    fastDropDelta = prefs.getInt(_TNames.fastDropDelta.name, defaultValue: -20)!;
    fastRiseDelta = prefs.getInt(_TNames.fastRiseDelta.name, defaultValue: 20)!;

    effect(() => prefs.setInt(_TNames.fastDropDelta.name, fastDropDelta));

    effect(() => prefs.setInt(_TNames.fastRiseDelta.name, fastRiseDelta));

    effect(() => prefs.setInt(_TNames.highTarget.name, highTarget));

    effect(() => prefs.setInt(_TNames.lowTarget.name, lowTarget));

    effect(() => prefs.setInt(_TNames.highUrgent.name, highUrgent));

    effect(() => prefs.setInt(_TNames.lowUrgent.name, lowUrgent));
  }
}
