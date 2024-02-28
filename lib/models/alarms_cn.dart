import 'package:carer/models/settings_cn.dart';
import 'package:carer/models/summary_cn.dart';
import 'package:flutter/material.dart';

enum AlarmNames {
  lowAlarm,
  highAlarm,
  noAlarm,
}

class AlarmsChangeNotifier extends ChangeNotifier {
  Settings settings;
  SummaryCN summaryCn;

  bool alarm = false;
  AlarmsChangeNotifier({required this.settings, required this.summaryCn}) {
    summaryCn.addListener(() {
      checkAlarms();
    });
  }

  void checkAlarms() {
    if (summaryCn.summary.lastSGV == null) {
      return;
    }
    var lastSGV = summaryCn.summary.lastSGV!;
    var sgv = lastSGV.sgv;

    if (sgv < settings.targetLow) {
      alarm = true;
      print("Low Alarm");
    } else if (sgv > settings.targetHigh && settings.highAlarm) {
      alarm = true;
      print("High Alarm");
    } else {
      alarm = false;
    }
  }
}
