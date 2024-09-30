import 'package:carer/services/alarms_service.dart';
import 'package:carer/services/settings/alarm_alert_settings.dart';
import 'package:carer/services/themes_service.dart';
import 'package:carer/services/timer_service.dart';
import 'package:carer/utils/futures.dart';
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
    var large = labelLarge(context).copyWith(
      height: 1,
      fontSize: 30,
    );

    var alarmText = alarmStringWidget(context);
    List<Widget> rows = [
      Expanded(
        flex: 10,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
          child: Text(
            "Snooze\n${snoozeString()}",
            style: large,
          ),
        ),
      ),
    ];

    if (alarmText != null) {
      rows.add(const Spacer());
      rows.add(alarmText);
    }
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

  String snoozeString() {
    if (!isSnoozing()) {
      return "";
    }
    var duration = AlarmAlertSettings().snoozeDuration!;
    var minutes = duration.inMinutes;
    var hours = duration.inHours;

    if (hours > 0) {
      return "${hours}h";
    }

    if (minutes > 0) {
      return "${minutes}m";
    }

    return "<1m";
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

    var alarmStrings = [];
    for (var alarm in triggeredAlarms) {
      alarmStrings.add(alarm.status());
    }

    return Text(alarmStrings.join(","), style: small);
  }
}
