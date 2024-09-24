import 'package:carer/services/alarms_service.dart';
import 'package:carer/services/settings/alarm_alert_settings.dart';
import 'package:carer/services/themes_service.dart';
import 'package:carer/services/timer_service.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/widgets/smarttext.dart';
import 'package:flutter/material.dart';

class SleepTextStatus extends StatelessWidget with ThemeMixin {
  final double buttonRadias;
  const SleepTextStatus(this.buttonRadias, {super.key});

  @override
  Widget build(BuildContext context) {
    return AWatch((context) {
      Widget spacer = SizedBox(height: buttonRadias, width: buttonRadias);

      List<Widget> rows = [
        spacer,
        Expanded(
          child: ClipRect(
            child: SizedBox(
              height: buttonRadias,
              child: Column(
                children: getRows(context),
              ),
            ),
          ),
        ),
        spacer
      ];

      return Container(
        alignment: Alignment.center,
        padding: EdgeInsets.zero,
        child: Row(children: rows),
      );
    }, dependencies: [TimerService().tenSecondSignal, AlarmAlertSettings().sleepUntilSignal], debugLabel: "SleepTextStatus");
  }

  List<Widget> getRows(BuildContext context) {
    var big = const TextStyle(
      fontSize: 35,
      height: 1,
      fontFeatures: [FontFeature.tabularFigures()],
    );

    var small = const TextStyle(fontSize: 20);
    List<Widget> rows = [];
    var alarmWidget = alarmStringWidget(context);
    if (isSleeping()) {
      rows += [
        const Spacer(),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Sleep ", style: small),
            Flexible(child: timeStringWidget()),
          ],
        ),
        const Spacer(),
      ];
    } else {
      rows += [
        const Spacer(),
        Text("Sleep", style: big),
        const Spacer(),
      ];
    }

    if (alarmWidget != null) {
      rows += [
        alarmWidget,
        const Spacer(),
      ];
    }

    return rows;
  }

  bool isSleeping() {
    var duration = AlarmAlertSettings().sleepDuration;
    if (duration == null) {
      return false;
    }
    var totalSeconds = duration.inSeconds;
    if (totalSeconds <= 0) {
      return false;
    }
    return true;
  }

  Widget timeStringWidget() {
    var big = const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, height: 1);
    var small = const TextStyle(fontSize: 20);

    var duration = AlarmAlertSettings().sleepDuration!;
    var totalSeconds = duration.inSeconds;

    var hours = (totalSeconds / 3600).floor();
    var minutes = ((totalSeconds % 3600) / 60).floor();

    if (hours > 0) {
      return SmartText(texts: ["$hours", "h"], styles: [big, small]);
    }

    if (minutes > 0) {
      return SmartText(texts: ["$minutes", "m"], styles: [big, small]);
    }

    return SmartText(texts: const ["<1m"], styles: [big]);
  }

  Widget? alarmStringWidget(BuildContext context) {
    var small = TextStyle(
      fontSize: 10,
      height: 1,
      color: tertiaryColor(context),
    );

    var triggeredAlarms = AlarmsService().triggeredAlarms.value;
    if (triggeredAlarms.isEmpty) {
      return null;
    }
    List<Widget> texts = [];

    for (var alarm in triggeredAlarms) {
      texts.add(Text(alarm.status(), style: small));
    }

    return Column(children: texts);
  }
}
