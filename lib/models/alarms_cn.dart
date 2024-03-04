import 'package:carer/models/settings_cn.dart';
import 'package:carer/utils/math.dart';
import 'package:carer/models/t1d_cn.dart';
import 'package:flutter/material.dart';

enum Alarms {
  targetVeryLow,
  targetLow,
  targetHigh,
  targetVeryHigh,

  diffVeryLow,
  diffVeryHigh,
}

class AlarmsChangeNotifier extends ChangeNotifier {
  T1DCN t1d;

  Set<Alarms> alarms = <Alarms>{};

  AlarmsChangeNotifier({required this.t1d}) {
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

    if (newAlarms != alarms) {
      // Set alarms
      alarms = newAlarms;
      if (alarms.isEmpty) {
        clearAlarm();
      } else {
        createAlarms(alarms);
      }
      notifyListeners();
    }
  }

  void clearAlarm() {
    print("Clear Alarm");
  }

  void createAlarms(Set<Alarms> alarms) {
    print("Create Alarms $alarms");
  }
}
