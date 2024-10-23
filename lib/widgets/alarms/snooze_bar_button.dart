import 'package:carer/services/alarms_service.dart';
import 'package:carer/services/settings/alarm_alert_settings.dart';
import 'package:carer/services/settings/alarm_settings.dart';
import 'package:carer/services/themes_service.dart';
import 'package:carer/services/timer_service.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/widgets/alarms/snoozetime_page.dart';
import 'package:flutter/material.dart';

class SnoozeBarButton extends StatelessWidget with ThemeMixin {
  const SnoozeBarButton({super.key});

  @override
  Widget build(BuildContext context) {
    return AWatch(
      (BuildContext context) {
        if (AlarmSettings().disableAlarms) {
          return const SizedBox.shrink();
        }

        ButtonStyle buttonStyle = ElevatedButton.styleFrom(
          foregroundColor: Colors.black,
          backgroundColor: primaryColor(context),
          padding: const EdgeInsets.all(5),
          minimumSize: const Size(100, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        );

        Widget snoozeIcon = const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [Icon(Icons.bedtime_outlined), Text("Snooze")],
        );

        Widget snoozeText = Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: alarmStrings() + snoozeStrings(context),
        );

        return ElevatedButton(
          style: buttonStyle,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) {
                return const SnoozeTimePage(10);
              }),
            );
          },
          child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [snoozeIcon, snoozeText]),
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
      Text(
        alarmStrings.join("\n"),
      )
    ];
  }
}
