import 'package:carer/services/alarms_service.dart';
import 'package:carer/services/settings/alarm_alert_settings.dart';
import 'package:carer/services/settings/alarm_settings.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/widgets/alarms/snoozetime_page.dart';
import 'package:flutter/material.dart';

class SnoozeFloatingButton extends StatelessWidget {
  const SnoozeFloatingButton({super.key});

  @override
  Widget build(BuildContext context) {
    return AWatch(
      (BuildContext context) {
        if (AlarmSettings().disableAlarms) {
          return const SizedBox.shrink();
        }

        Widget sleepIcon = const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [Icon(Icons.bedtime_outlined), Text("Sleep")],
        );
        if (AlarmAlertSettings().snoozeDuration == null && AlarmsService().pendingAlarms.value.isEmpty) {
          return FloatingActionButton(
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
              child: sleepIcon);
        }

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
          icon: sleepIcon,
          label: const SizedBox.shrink(),
        );
      },
      debugLabel: "SnoozeFloatingButton",
      dependencies: [AlarmSettings().disableAlarmsSignal, AlarmAlertSettings().snoozeUntilSignal, AlarmsService().pendingAlarms],
    );
  }
}
