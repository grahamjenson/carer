import 'package:carer/services/alarms_service.dart';
import 'package:carer/services/settings/alarm_alert_settings.dart';
import 'package:carer/services/themes_service.dart';
import 'package:carer/services/timer_service.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/widgets/smarttext.dart';
import 'package:flutter/material.dart';

class SnoozeTextStatus extends StatelessWidget with ThemeMixin {
  const SnoozeTextStatus({super.key});

  @override
  Widget build(BuildContext context) {
    return AWatch((context) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: getRows(context),
      );
    }, dependencies: [TimerService().tenSecondSignal, AlarmAlertSettings().snoozeUntilSignal], debugLabel: "SnoozeTextStatus");
  }

  List<Widget> getRows(BuildContext context) {
    List<Widget> rows = [
      const Text("Snooze"),
    ];

    if (isSnoozing()) {
      rows.add(timeStringWidget(context));
    }

    var alarmWidget = alarmStringWidget(context);
    rows.add(alarmWidget);

    return rows;
  }

  bool isSnoozing() {
    var duration = AlarmAlertSettings().snoozeDuration;
    if (duration == null) {
      return false;
    }
    var totalSeconds = duration.inSeconds;
    if (totalSeconds <= 0) {
      return false;
    }
    return true;
  }

  Widget timeStringWidget(BuildContext context) {
    var big = labelLarge(context);
    var small = labelSmall(context);

    var duration = AlarmAlertSettings().snoozeDuration!;
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

  Widget alarmStringWidget(BuildContext context) {
    var small = TextStyle(
      fontSize: 10,
      height: 1,
      color: tertiaryColor(context),
    );

    var triggeredAlarms = AlarmsService().triggeredAlarms.value;
    if (triggeredAlarms.isEmpty) {
      return const SizedBox.shrink();
    }

    var alarmStrings = [];
    for (var alarm in triggeredAlarms) {
      alarmStrings.add(alarm.status());
    }

    return Text(alarmStrings.join(","), style: small);
  }
}
