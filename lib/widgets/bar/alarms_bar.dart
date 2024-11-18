import 'package:carer/models/details/alarms/alarms.dart';
import 'package:carer/services/alarms_service.dart';
import 'package:carer/services/settings/alarm_alert_settings.dart';
import 'package:carer/services/themes_service.dart';
import 'package:carer/utils/futures.dart';
import 'package:flutter/material.dart';

class AlarmsBarIcons extends StatelessWidget with ThemeMixin {
  AlarmsBarIcons({super.key});

  @override
  Widget build(BuildContext context) {
    return AWatch(
      (context) {
        var pendingAlarms = AlarmsService().pendingAlarms.value;

        if (pendingAlarms.isEmpty) {
          return const SizedBox.shrink();
        }

        return Center(
          child: FittedBox(
            child: Container(
              padding: const EdgeInsets.all(4), // Add padding inside the border
              decoration: BoxDecoration(
                border: Border.all(
                  color: badColor(context), // Color of the border
                  width: 1, // Width of the border
                ),
                borderRadius: BorderRadius.circular(5), // Optional: if you want rounded corners
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: getAlarmWidgets(pendingAlarms, badColor(context)),
              ),
            ),
          ),
        );
      },
      debugLabel: "AlarmsBarIcons",
      dependencies: [ThemeService().themeSignal, AlarmAlertSettings().snoozeUntilSignal],
    );
  }

  List<Widget> getAlarmWidgets(AlarmSet triggeredAlarms, Color color) {
    List<Widget> alarmWidgets = [];
    for (var alarm in triggeredAlarms) {
      alarmWidgets.add(getAlarmToolTip(alarm, color));
    }
    return alarmWidgets;
  }

  static Tooltip getAlarmToolTip(AlarmType alarm, Color color) {
    return Tooltip(
      message: alarm.shortSummary(),
      triggerMode: TooltipTriggerMode.tap,
      child: Icon(
        alarm.icon,
        color: color,
      ),
    );
  }
}
