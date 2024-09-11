import 'package:carer/services/alarms_service.dart';
import 'package:carer/services/themes_service.dart';
import 'package:carer/services/timer_service.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/widgets/smarttext.dart';
import 'package:flutter/material.dart';

class SleepTextStatus extends StatelessWidget with ThemeMixin {
  const SleepTextStatus({super.key});

  @override
  Widget build(BuildContext context) {
    var big = const TextStyle(
      fontSize: 35,
      fontFeatures: [FontFeature.tabularFigures()],
    );
    var small = getSmallTextStyle();

    return AWatch((context) {
      List<Widget> rows = [];
      if (isSleeping()) {
        rows = [sleepStringWidget(), alarmStringWidget(small)];
      } else {
        rows = [Text("Sleep", style: big), alarmStringWidget(small)];
      }

      return Container(
        alignment: Alignment.center,
        padding: EdgeInsets.zero,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: rows),
      );
    }, dependencies: [TimerService().tenSecondSignal, AlarmsService().sleepUntilSignal], debugLabel: "SleepTextStatus");
  }

  bool isSleeping() {
    var duration = AlarmsService().sleepDuration;
    if (duration == null) {
      return false;
    }
    var totalSeconds = duration.inSeconds;
    if (totalSeconds <= 0) {
      return false;
    }
    return true;
  }

  Widget sleepStringWidget() {
    var big = const TextStyle(fontSize: 40, fontWeight: FontWeight.bold);
    var small = const TextStyle(fontSize: 20);

    var duration = AlarmsService().sleepDuration!;
    var totalSeconds = duration.inSeconds;

    var hours = (totalSeconds / 3600).floor();
    var minutes = ((totalSeconds % 3600) / 60).floor();

    if (hours > 0) {
      if (minutes == 0) {
        return SmartText(texts: ["Sleep ", "$hours", "h"], styles: [small, big, small]);
      }
      return SmartText(texts: ["Sleep ", "$hours", "h", "$minutes", "m"], styles: [small, big, small, big, small]);
    }

    if (minutes > 0) {
      return SmartText(texts: ["Sleep ", " $minutes", "m"], styles: [small, big, small]);
    }

    return SmartText(texts: const ["Sleep ", "<1m"], styles: [small, big]);
  }

  Widget alarmStringWidget(TextStyle style) {
    var triggeredAlarms = AlarmsService().triggeredAlarms.value;
    if (triggeredAlarms.isEmpty) {
      return const SizedBox.shrink();
    }
    List<String> texts = [];
    List<TextStyle> styles = [];
    for (var alarm in triggeredAlarms) {
      texts.add(alarm.status());
      styles.add(style);
    }

    return SmartText(texts: texts, styles: styles);
  }
}
