import 'package:carer/sql/key_value_store.dart';
import 'package:signals/signals.dart';

// find where in the target range and by what proportion a number is
// returns a tuple of (Targets, proportion)

enum _TNames {
  targetHigh,
  targetLow,
  urgentHigh,
  urgentLow,
}

class TargetSettings {
  static final TargetSettings _singleton = TargetSettings._();
  factory TargetSettings() => _singleton;

  final Map<_TNames, Signal<int>> _signals = {
    _TNames.targetHigh: Signal<int>(180, debugLabel: 'targetHigh'),
    _TNames.targetLow: Signal<int>(72, debugLabel: 'targetLow'),
    _TNames.urgentHigh: Signal<int>(270, debugLabel: 'urgentHigh'),
    _TNames.urgentLow: Signal<int>(55, debugLabel: 'urgentLow'),
  };

  TargetSettings._();

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

  bool validTargets(
      int urgentLow, int targetLow, int targetHigh, int urgentHigh) {
    return 9 <= urgentLow &&
        urgentLow <= targetLow &&
        targetLow <= targetHigh &&
        targetHigh <= urgentHigh &&
        urgentHigh <= 360;
  }

  setupDBPropagation() async {
    var prefs = await KeyValueStore.instance;

    effect(() => prefs.setInt(_TNames.targetHigh.name, targetHigh));

    effect(() => prefs.setInt(_TNames.targetLow.name, targetLow));

    effect(() => prefs.setInt(_TNames.urgentHigh.name, urgentHigh));

    effect(() => prefs.setInt(_TNames.urgentLow.name, urgentLow));
  }
}
