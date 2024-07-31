import 'package:carer/services/alarms/alarms.dart';
import 'package:carer/services/alarms_service.dart';
import 'package:carer/services/audio_info_service.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/widgets/colours.dart';
import 'package:carer/widgets/pages/settingspage.dart';
import 'package:flutter/material.dart';

class Bar extends StatelessWidget {
  const Bar({super.key});

  @override
  Widget build(BuildContext context) {
    return AWatch((context) {
      List<Widget> tiles = [
        getIsSilentOnIcon(),
        getTriggeredAlarmIcons(),
        const Expanded(
          child: SizedBox.shrink(),
        ),
        getSettingsButton(context),
      ];

      return BottomAppBar(
        color: Colors.transparent,
        padding: const EdgeInsets.only(left: 8, right: 8),
        height: 40,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: tiles,
        ),
      );
    });
  }

  Widget getSettingsButton(BuildContext context) {
    return IconButton(
      padding: EdgeInsets.zero,
      icon: const Icon(
        Icons.settings,
        color: mainColor,
      ),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SettingsPage()),
        );
      },
    );
  }

  Widget getTriggeredAlarmIcons() {
    var triggeredAlarms = AlarmsService().triggeredAlarms.value;

    List<Widget> alarmWidgets = [];
    for (var alarm in triggeredAlarms) {
      alarmWidgets.add(AlarmIcons.getAlarmToolTip(alarm));
    }
    return Row(
      children: alarmWidgets,
    );
  }

  Widget getIsSilentOnIcon() {
    var ringer = AudioInfoService().ringerMode.value;
    if (ringer == RingerMode.silent || ringer == RingerMode.vibrate) {
      return const Tooltip(
          message: "Silent Mode",
          triggerMode: TooltipTriggerMode.tap,
          child: Icon(
            Icons.volume_off,
            color: mainColor,
          ));
    } else {
      return const SizedBox.shrink();
    }
  }
}

class AlarmIcons {
  // Icons
  static const IconData highAlarm = Icons.warning; // Example for High Alarm
  static const IconData urgentHighAlarm = Icons.warning_amber; // Example for Urgent High Alarm
  static const IconData lowAlarm = Icons.priority_high; // Example for Low Alarm
  static const IconData urgentLowAlarm = Icons.add_alert; // Example for Urgent Low Alarm

  // Map
  static Tooltip getAlarmToolTip(Alarm alarm) {
    switch (alarm.runtimeType) {
      case HighAlarm:
        return const Tooltip(
          message: "High Alarm",
          triggerMode: TooltipTriggerMode.tap,
          child: Icon(
            highAlarm,
            color: mainColor,
          ),
        );
      case UrgentHighAlarm:
        return const Tooltip(
          message: "Urgent High Alarm",
          triggerMode: TooltipTriggerMode.tap,
          child: Icon(
            urgentHighAlarm,
            color: mainColor,
          ),
        );
      case LowAlarm:
        return const Tooltip(
          message: "Low Alarm",
          triggerMode: TooltipTriggerMode.tap,
          child: Icon(
            lowAlarm,
            color: mainColor,
          ),
        );
      case UrgentLowAlarm:
        return const Tooltip(
          message: "Urgent Low Alarm",
          triggerMode: TooltipTriggerMode.tap,
          child: Icon(
            urgentLowAlarm,
            color: mainColor,
          ),
        );
      default:
        return const Tooltip(
          message: "Unknown Alarm",
          triggerMode: TooltipTriggerMode.tap,
          child: Icon(
            Icons.error,
            color: mainColor,
          ),
        );
    }
  }
}
