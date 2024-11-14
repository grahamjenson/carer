import 'package:carer/models/sql/constants.dart';
import 'package:carer/sql/key_value_store.dart';
import 'package:carer/utils/futures.dart';
import 'package:flutter/material.dart';

enum _UINames {
  unit,
  screenActive,

  enableDim,

  // Ephemeril
  orientation,
}

class UISettings {
  static final UISettings _singleton = UISettings._();
  factory UISettings() => _singleton;

  final Map<_UINames, ASignal> _signals = {
    _UINames.screenActive: ASignal<bool>(false, debugLabel: 'screenActive'),
    _UINames.unit: ASignal<Unit>(Unit.mg, debugLabel: 'unit'),
    _UINames.enableDim: ASignal<bool>(false, debugLabel: 'enableDim'),
    _UINames.orientation: ASignal<Orientation>(Orientation.portrait, debugLabel: 'orientation'),
  };

  UISettings._();

  List<ASignal> get allSignals => _signals.values.toList();

  bool get screenActive => _signals[_UINames.screenActive]!.value as bool;
  set screenActive(bool value) => _signals[_UINames.screenActive]!.value = value;

  Unit get unit => _signals[_UINames.unit]!.value as Unit;
  set unit(Unit value) => _signals[_UINames.unit]!.value = value;

  bool get enableDim => _signals[_UINames.enableDim]!.value as bool;
  set enableDim(bool value) => _signals[_UINames.enableDim]!.value = value;

  // Ephemeril
  ASignal get orientationSignal => _signals[_UINames.orientation]!;
  Orientation get orientation => _signals[_UINames.orientation]!.value as Orientation;
  set orientation(Orientation value) => _signals[_UINames.orientation]!.value = value;

  setupDBPropagation(KeyValueStore prefs) {
    // Assign the values from the DB
    screenActive = prefs.getBool(_UINames.screenActive.name, defaultValue: true)!;

    unit = Unit.fromBool(prefs.getBool(_UINames.unit.name, defaultValue: true)!);

    enableDim = prefs.getBool(_UINames.enableDim.name, defaultValue: false)!;

    aeffect(() => prefs.setBool(_UINames.unit.name, unit.toBool()), debugLabel: _UINames.unit.name);

    aeffect(() {
      prefs.setBool(_UINames.screenActive.name, screenActive);
    }, debugLabel: _UINames.screenActive.name);

    aeffect(() {
      prefs.setBool(_UINames.enableDim.name, enableDim);
    }, debugLabel: _UINames.enableDim.name);
  }
}
