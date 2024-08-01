import 'package:carer/services/alarms_service.dart';
import 'package:carer/services/timer_service.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/widgets/colours.dart';
import 'package:carer/widgets/smarttext.dart';
import 'package:flutter/material.dart';

const big = TextStyle(
  color: mainColor,
  fontSize: 20,
  fontFeatures: [FontFeature.tabularFigures()],
);

const small = TextStyle(
  color: mainColor,
  fontSize: 10,
);

class SleepTextStatus extends StatelessWidget {
  const SleepTextStatus({super.key});

  @override
  Widget build(BuildContext context) {
    return AWatch((context) {
      List<Widget> rows = [];
      if (isSleeping()) {
        rows = [sleepStringWidget(), alarmStringWidget(small)];
      } else {
        rows = [const Text("Sleep", style: big), alarmStringWidget(small)];
      }

      return Container(
        alignment: Alignment.center,
        padding: EdgeInsets.zero,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: rows),
      );
    }, dependencies: [TimerService().tenSecondSignal, AlarmsService().sleepUntilSignal]);
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
}

Widget sleepStringWidget() {
  var duration = AlarmsService().sleepDuration!;
  var totalSeconds = duration.inSeconds;

  var hours = (totalSeconds / 3600).floor();
  var minutes = ((totalSeconds % 3600) / 60).floor();

  if (hours > 0) {
    if (minutes == 0) {
      return SmartText(texts: ["Sleep $hours", "h"], styles: const [big, small]);
    }
    return SmartText(texts: ["Sleep $hours", "h", "$minutes", "m"], styles: const [big, small, big, small]);
  }

  if (minutes > 0) {
    return SmartText(texts: ["Sleep $minutes", "m"], styles: const [big, small]);
  }

  return SmartText(texts: const ["Sleep <1m"], styles: const [big]);
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
