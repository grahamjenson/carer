import 'package:carer/models/details/alarms/alarms.dart';
import 'package:carer/services/alarms_service.dart';
import 'package:carer/services/themes_service.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/widgets/insights/window.dart';
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

      return Expanded(
        flex: flex,
        child: Window(
          child: FittedBox(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(alarm.icon, color: alarmStyle.color, size: alarmStyle.fontSize! * 0.8),
                Text(alarm.statment(), style: alarmStyle),
              ],
            ),
          ),
        ),
      );
    }, debugLabel: "AlarmWidget", dependencies: [AlarmsService().pendingAlarms]);
  }
}
