import 'package:carer/services/alarms_service.dart';
import 'package:carer/services/settings/alarm_alert_settings.dart';
import 'package:carer/services/settings/alarm_settings.dart';
import 'package:carer/services/themes_service.dart';
import 'package:carer/services/timer_service.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/widgets/alarms/snoozetime_page.dart';
import 'package:flutter/material.dart';

class SnoozeFloatingButton extends StatelessWidget with ThemeMixin {
  const SnoozeFloatingButton({super.key});

  @override
  Widget build(BuildContext context) {
    return AWatch(
      (BuildContext context) {
        if (AlarmSettings().disableAlarms) {
          return const SizedBox.shrink();
        }

        Widget snoozeIcon = const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [Icon(Icons.bedtime_outlined), Text("Snooze")],
        );
        if (AlarmAlertSettings().snoozeDuration == null && AlarmsService().pendingAlarms.value.isEmpty) {
          return FloatingActionButton.extended(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) {
                  return const SnoozeTimePage(10);
                }),
              );
            },
            label: Container(margin: const EdgeInsets.all(5), child: snoozeIcon),
          );
        }

        Widget snoozeText = Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: alarmStrings() + snoozeStrings(context),
        );

        return FloatingActionButton.extended(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          extendedPadding: const EdgeInsets.all(5),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) {
                return const SnoozeTimePage(10);
              }),
            );
          },
          icon: snoozeIcon,
          label: snoozeText,
        );
      },
      debugLabel: "SnoozeFloatingButton",
      dependencies: [
        AlarmSettings().disableAlarmsSignal,
        AlarmAlertSettings().snoozeUntilSignal,
        AlarmsService().pendingAlarms,
        TimerService().tenSecondSignal,
      ],
    );
  }

  List<Widget> snoozeStrings(BuildContext context) {
    if (AlarmAlertSettings().snoozeDuration == null) {
      return [];
    }
    return [
      Text(
        AlarmAlertSettings().snoozeString(),
        style: labelLarge(context).copyWith(
          fontSize: 20,
          color: Colors.black,
        ),
      ),
    ];
  }

  List<Widget> alarmStrings() {
    var pendingAlarms = AlarmsService().pendingAlarms.value;
    if (pendingAlarms.isEmpty) {
      return [];
    }

    var alarmStrings = [];
    for (var alarm in pendingAlarms) {
      alarmStrings.add(alarm.shortSummary());
    }

    return [
      FittedBox(
          fit: BoxFit.contain,
          child: Text(
            alarmStrings.join("\n"),
          ))
    ];
  }
}
