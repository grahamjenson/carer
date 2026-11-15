import 'package:carer/models/sql/constants.dart';
import 'package:carer/services/alarms_service.dart';
import 'package:carer/services/app_lifecycle_service.dart';
import 'package:carer/services/timer_service.dart';
import 'package:carer/sql/key_value_store.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/utils/logs.dart';
import 'package:carer/widgets/router.dart';
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';

enum _UINames {
  unit,
  screenActive,

  enableDim,

  // Ephemeril
  orientation,
  focusBGL,
  chartMinsAgo,
}

class UISettings {
  static final UISettings _singleton = UISettings._();
  factory UISettings() => _singleton;

  final Map<_UINames, ASignal> _signals = {
    _UINames.screenActive: ASignal<bool>(false, debugLabel: 'screenActive'),
    _UINames.unit: ASignal<Unit>(Unit.mg, debugLabel: 'unit'),
    _UINames.enableDim: ASignal<bool>(false, debugLabel: 'enableDim'),
    // Ephemeril
    _UINames.orientation: ASignal<Orientation>(Orientation.portrait, debugLabel: 'orientation'),
    _UINames.focusBGL: ASignal<bool>(false, debugLabel: 'focusBGL'),
    _UINames.chartMinsAgo: ASignal<int>(120, debugLabel: 'chartMinsAgo'),
  };

  UISettings._();

  List<ASignal> get allSignals => _signals.values.toList();

  bool get screenActive => _signals[_UINames.screenActive]!.value as bool;
  set screenActive(bool value) => _signals[_UINames.screenActive]!.value = value;

  Unit get unit => _signals[_UINames.unit]!.value as Unit;
  set unit(Unit value) => _signals[_UINames.unit]!.value = value;
  ASignal get unitSignal => _signals[_UINames.unit]!;

  bool get enableDim => _signals[_UINames.enableDim]!.value as bool;
  set enableDim(bool value) => _signals[_UINames.enableDim]!.value = value;

  // Ephemeril
  ASignal get orientationSignal => _signals[_UINames.orientation]!;
  Orientation get orientation => _signals[_UINames.orientation]!.value as Orientation;
  set orientation(Orientation value) => _signals[_UINames.orientation]!.value = value;

  /// If true, the BGL will be displayed in a total.
  ASignal<bool> get focusBGLSignal => _signals[_UINames.focusBGL]! as ASignal<bool>;
  bool get focusBGL => _signals[_UINames.focusBGL]!.value as bool;
  set focusBGL(bool value) => _signals[_UINames.focusBGL]!.value = value;
  void toggleFocusBGL() {
    focusBGL = !focusBGL;
  }

  ASignal<int> get chartMinsAgoSignal => _signals[_UINames.chartMinsAgo]! as ASignal<int>;
  int get chartHoursAgo => _signals[_UINames.chartMinsAgo]!.value ~/ 60;
  set chartHoursAgo(int value) => _signals[_UINames.chartMinsAgo]!.value = value * 60;

  // Setup

  setupDBPropagation(KeyValueStore prefs) {
    // Assign the values from the DB
    screenActive = prefs.getBool(_UINames.screenActive.name, defaultValue: true)!;

    unit = Unit.fromBool(prefs.getBool(_UINames.unit.name, defaultValue: true)!);

    enableDim = prefs.getBool(_UINames.enableDim.name, defaultValue: false)!;

    aeffect(() => prefs.setBool(_UINames.unit.name, unit.toBool()), debugLabel: "writeUnit");

    aeffect(() {
      prefs.setBool(_UINames.screenActive.name, screenActive);
    }, debugLabel: 'writeCcreenActive');

    aeffect(() {
      prefs.setBool(_UINames.enableDim.name, enableDim);
    }, debugLabel: "writeEnableDim");

    // Turn off focus mode if alarms become active
    aeffect(
      () {
        if (AlarmsService().alertingAlarms.value.isNotEmpty) {
          focusBGL = false;
        }
      },
      dependencies: [AlarmsService().alertingAlarms, TimerService().fiveSecondSignal],
      debugLabel: "focusBGLOffOnAlarms",
    );

    DateTime? lastInteractionReset;
    // If there is an no interaction for 5 minutes we need
    aeffect(() {
      // We peek because we don't need to check the value every change
      var lastInteraction = AppLifecycleService().lastInteraction.peek();
      if (lastInteraction == lastInteractionReset) {
        // If the last interaction is the same as the reset, we don't need to reset
        return;
      }

      var diff = clock.now().difference(lastInteraction).inSeconds;
      if (diff >= 300) {
        lastInteractionReset = lastInteraction;
        alog("Resetting UI to display");
        chartHoursAgo = 2;
        if (router != null) {
          router!.go("/display");
        }
      }
    }, dependencies: [TimerService().fifteenSecondSignal], debugLabel: "ResetUIWithNoScreenInteration");
  }
}
