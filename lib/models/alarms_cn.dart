import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:carer/models/settings_cn.dart';
import 'package:carer/utils/dates.dart';
import 'package:carer/utils/math.dart';
import 'package:carer/models/t1d_cn.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

enum Alarms {
  targetVeryLow,
  targetLow,
  targetHigh,
  targetVeryHigh,

  diffVeryLow,
  diffVeryHigh,
}

const se = SetEquality();

class AlarmsCN extends ChangeNotifier {
  T1DCN t1d;
  Settings settings;

  Set<Alarms> alarms = <Alarms>{};

  // Minutes of sleep time
  DateTime _sleepUntil = DateTime.now();
  DateTime get sleepUntil => _sleepUntil;
  set sleepUntil(DateTime value) {
    _sleepUntil = value;
    notifyListeners();
  }

  Duration get sleepDuration => _sleepUntil.difference(DateTime.now());
  set sleepDurationSeconds(int value) {
    _sleepUntil = DateTime.now().add(Duration(seconds: value));
    notifyListeners();
  }

  final player = AudioPlayer();

  AlarmsCN({required this.t1d, required this.settings}) {
    Timer.periodic(const Duration(seconds: 1), (Timer t) => checkAlarms());

    settings.addListener(() {
      checkAlarms();
    });

    t1d.addListener(() {
      checkAlarms();
    });
  }

  void checkAlarms() {
    var newAlarms = <Alarms>{};

    switch (t1d.targetRange5) {
      case Range5.veryLow:
        newAlarms.add(Alarms.targetVeryLow);
        break;
      case Range5.low:
        newAlarms.add(Alarms.targetLow);
        break;
      case Range5.high:
        newAlarms.add(Alarms.targetHigh);
        break;
      case Range5.veryHigh:
        newAlarms.add(Alarms.targetVeryHigh);
        break;
      default:
        break;
    }

    switch (t1d.diffRange7) {
      case Range7.veryVeryLow:
        newAlarms.add(Alarms.diffVeryLow);
        break;
      case Range7.veryLow:
        newAlarms.add(Alarms.diffVeryLow);
        break;
      case Range7.veryHigh:
        newAlarms.add(Alarms.diffVeryHigh);
        break;
      case Range7.veryVeryHigh:
        newAlarms.add(Alarms.diffVeryHigh);
        break;
      default:
        break;
    }

    // Filter Alarms that are not enabled
    filterAlarms(newAlarms);

    if (!se.equals(newAlarms, alarms)) {
      notifyListeners();
      // Set alarms
      alarms = newAlarms;
      if (alarms.isEmpty) {
        clearAlarm();
      } else {
        createAlarms(alarms);
      }
    }
  }

  void clearAlarm() {
    print("Clear Alarm");
    player.stop();
  }

  void createAlarms(Set<Alarms> alarms) {
    print("Create Alarms $alarms");
    player.play(AssetSource("alarm.mp3"));
  }

  filterAlarms(Set<Alarms> alarms) {
    if (sleepDuration.inSeconds > 0) {
      // We are sleeping, no alarms right now
      alarms.clear();
      return;
    }

    if (!settings.highAlarm) {
      alarms.remove(Alarms.targetHigh);
      alarms.remove(Alarms.targetVeryHigh);
      alarms.remove(Alarms.diffVeryHigh);
    }

    if (!settings.lowAlarm) {
      alarms.remove(Alarms.targetLow);
      alarms.remove(Alarms.targetVeryLow);
      alarms.remove(Alarms.diffVeryLow);
    }
  }
}
