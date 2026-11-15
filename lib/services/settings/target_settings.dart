// ignore_for_file: constant_identifier_names

import 'package:carer/sql/key_value_store.dart';
import 'package:carer/utils/futures.dart';

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

const MIN_TARGET = 40.0;
const MAX_TARGET = 280.0;
const MAX_DELTA = 36.0;

class TargetSettings {
  static final TargetSettings _singleton = TargetSettings._();
  factory TargetSettings() => _singleton;

  final Map<_TNames, ASignal<double>> _signals = {
    // These are doubles because mmol/mg doesnt easily divide
    _TNames.highTarget: ASignal<double>(180, debugLabel: 'highTarget'),
    _TNames.lowTarget: ASignal<double>(72, debugLabel: 'lowTarget'),
    _TNames.highUrgent: ASignal<double>(270, debugLabel: 'highUrgent'),
    _TNames.lowUrgent: ASignal<double>(55, debugLabel: 'lowUrgent'),
    _TNames.fastDropDelta: ASignal<double>(9, debugLabel: 'fastDropDelta'),
    _TNames.fastRiseDelta: ASignal<double>(-9, debugLabel: 'fastRiseDelta'),
  };

  TargetSettings._();

  allValues() {
    for (var signal in _signals.values) {
      var _ = signal.value;
    }
  }

  List<ASignal> allSignals() {
    return _signals.values.toList();
  }

  double get highTarget => _signals[_TNames.highTarget]!.value;
  double get highTargetPeek => _signals[_TNames.highTarget]!.peek();
  set highTarget(double value) {
    if (!validTargets(lowUrgent, lowTarget, value, highUrgent)) {
      return;
    }
    _signals[_TNames.highTarget]!.value = value;
  }

  double get lowTarget => _signals[_TNames.lowTarget]!.value;
  double get lowTargetPeek => _signals[_TNames.lowTarget]!.peek();

  set lowTarget(double value) {
    if (!validTargets(lowUrgent, value, highTarget, highUrgent)) {
      return;
    }
    _signals[_TNames.lowTarget]!.value = value;
  }

  double get highUrgent => _signals[_TNames.highUrgent]!.value;
  double get highUrgentPeek => _signals[_TNames.highUrgent]!.peek();
  set highUrgent(double value) {
    if (!validTargets(lowUrgent, lowTarget, highTarget, value)) {
      return;
    }
    _signals[_TNames.highUrgent]!.value = value;
  }

  double get lowUrgent => _signals[_TNames.lowUrgent]!.value;
  double get lowUrgentPeek => _signals[_TNames.lowUrgent]!.peek();
  set lowUrgent(double value) {
    if (!validTargets(value, lowTarget, highTarget, highUrgent)) {
      return;
    }
    _signals[_TNames.lowUrgent]!.value = value;
  }

  double get fastDropDelta => _signals[_TNames.fastDropDelta]!.value.toDouble();
  double get fastDropDeltaPeek => _signals[_TNames.fastDropDelta]!.peek().toDouble();

  set fastDropDelta(double value) => fastDropDeltaSet(_signals[_TNames.fastDropDelta]!, value);

  double get fastRiseDelta => _signals[_TNames.fastRiseDelta]!.value.toDouble();
  double get fastRiseDeltaPeek => _signals[_TNames.fastRiseDelta]!.peek().toDouble();

  set fastRiseDelta(double value) => fastRiseDeltaSet(_signals[_TNames.fastRiseDelta]!, value);

  bool validTargets(num lowUrgent, num lowTarget, num highTarget, num highUrgent) {
    return MIN_TARGET <= lowUrgent && lowUrgent <= lowTarget && lowTarget <= highTarget && highTarget <= highUrgent && highUrgent <= MAX_TARGET;
  }

  fastDropDeltaSet(ASignal<double> signal, double value) {
    if (value > -8) {
      value = -8;
    }
    if (value < -MAX_DELTA) {
      value = -MAX_DELTA;
    }
    signal.value = value;
  }

  fastRiseDeltaSet(ASignal<double> signal, double value) {
    if (value < 8) {
      value = 8;
    }
    if (value > MAX_DELTA) {
      value = MAX_DELTA;
    }
    signal.value = value;
  }

  setupDBPropagation(KeyValueStore prefs) {
    highTarget = prefs.getDouble(_TNames.highTarget.name) ?? 180.0;
    lowTarget = prefs.getDouble(_TNames.lowTarget.name) ?? 72.0;
    highUrgent = prefs.getDouble(_TNames.highUrgent.name) ?? 270.0;
    lowUrgent = prefs.getDouble(_TNames.lowUrgent.name) ?? 55.0;
    fastDropDelta = prefs.getDouble(_TNames.fastDropDelta.name, defaultValue: -20)!;
    fastRiseDelta = prefs.getDouble(_TNames.fastRiseDelta.name, defaultValue: 20)!;

    aeffect(() => prefs.setDouble(_TNames.fastDropDelta.name, fastDropDelta), debugLabel: 'writeFastDropDelta');

    aeffect(() => prefs.setDouble(_TNames.fastRiseDelta.name, fastRiseDelta), debugLabel: 'writeFastRiseDelta');

    aeffect(() => prefs.setDouble(_TNames.highTarget.name, highTarget), debugLabel: 'writehighTarget');

    aeffect(() => prefs.setDouble(_TNames.lowTarget.name, lowTarget), debugLabel: 'writelowTarget');

    aeffect(() => prefs.setDouble(_TNames.highUrgent.name, highUrgent), debugLabel: 'writehighUrgent');

    aeffect(() => prefs.setDouble(_TNames.lowUrgent.name, lowUrgent), debugLabel: 'writelowUrgent');
  }
}
