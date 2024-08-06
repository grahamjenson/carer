import 'package:carer/services/alarms/alarms.dart';
import 'package:carer/services/alarms_service.dart';
import 'package:carer/services/themes_service.dart';
import 'package:carer/utils/futures.dart';
import 'package:flutter/material.dart';

class AlarmsBarIcons extends StatelessWidget with ThemeMixin {
  AlarmsBarIcons({super.key});

  @override
  Widget build(BuildContext context) {
    return AWatch((context) {
      var triggeredAlarms = AlarmsService().triggeredAlarms.value;

      if (triggeredAlarms.isEmpty) {
        return const SizedBox.shrink();
      }

      return Container(
        padding: const EdgeInsets.all(4), // Add padding inside the border
        decoration: BoxDecoration(
          border: Border.all(
            color: primaryColor(context), // Color of the border
            width: 1, // Width of the border
          ),
          borderRadius: BorderRadius.circular(5), // Optional: if you want rounded corners
        ),
        child: Row(
          children: getAlarmWidgets(triggeredAlarms, primaryColor(context)),
        ),
      );
    });
  }

  List<Widget> getAlarmWidgets(Set<Alarm> triggeredAlarms, Color mainColor) {
    List<Widget> alarmWidgets = [];
    for (var alarm in triggeredAlarms) {
      alarmWidgets.add(getAlarmToolTip(alarm, mainColor));
    }
    return alarmWidgets;
  }

  static Tooltip getAlarmToolTip(Alarm alarm, Color mainColor) {
    return Tooltip(
      message: alarm.status(),
      triggerMode: TooltipTriggerMode.tap,
      child: Icon(
        alarm.icon(),
        color: mainColor,
      ),
    );
  }
}
