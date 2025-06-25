import 'package:carer/models/details/alarms/alarms.dart';
import 'package:carer/services/alarms_service.dart';
import 'package:carer/services/settings/alarm_alert_settings.dart';
import 'package:carer/services/themes_service.dart';
import 'package:carer/utils/futures.dart';
import 'package:flutter/material.dart';

class AlarmWidget extends StatelessWidget with ThemeMixin {
  final int flex;
  const AlarmWidget({super.key, this.flex = 1});

  @override
  Widget build(BuildContext context) {
    return AWatch((context) {
      var pendingAlarms = AlarmsService().pendingAlarms.value;
      if (pendingAlarms.isEmpty) {
        return const SizedBox.shrink();
      }

      var alarmStyle = displayLarge(context).merge(shadows(width: 1.5)).copyWith(color: primaryColor(context));

      AlarmType alarm = pendingAlarms.first;

      Widget fittedWidget =
          Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.center, children: [
        Icon(alarm.icon, color: alarmStyle.color, size: alarmStyle.fontSize! * 0.8),
        Text(alarm.statment(), style: alarmStyle),
      ]);

      if (alarm == AlarmType.test) {
        // Add a button to stop the test alarm
        fittedWidget = Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            fittedWidget,
            ElevatedButton(
              onPressed: () async {
                AlarmAlertSettings().testAlarm = false;
              },
              style: ElevatedButton.styleFrom(
                textStyle: alarmStyle,
                backgroundColor: primaryColor(context),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(8),
              ),
              child: const Text("Stop Test Alarm"),
            ),
          ],
        );
      }

      return Expanded(
        flex: flex,
        child: FittedBox(
          child: fittedWidget,
        ),
      );
    }, debugLabel: "AlarmWidget", dependencies: [AlarmsService().pendingAlarms]);
  }
}
