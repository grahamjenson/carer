import 'package:carer/services/alarms_service.dart';
import 'package:carer/services/settings/alarm_alert_settings.dart';
import 'package:carer/services/settings/alarm_settings.dart';
import 'package:carer/services/themes_service.dart';
import 'package:carer/services/timer_service.dart';
import 'package:carer/services/ui/icons.dart';
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

        Color buttonBackGroundColor = accentColor(context);
        if (AlarmAlertSettings().snoozeDuration != null) {
          buttonBackGroundColor = primaryColor(context);
        }

        ButtonStyle buttonStyle = ElevatedButton.styleFrom(
          foregroundColor: Colors.black,
          backgroundColor: buttonBackGroundColor,
          padding: const EdgeInsets.all(5),
          minimumSize: const Size(100, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        );

        Widget snoozeIcon = const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [Icon(CarerIcons.BAR_SNOOZE), Text("Snooze")],
        );

        List<Widget> children = [snoozeIcon];
        if (AlarmAlertSettings().snoozeDuration != null) {
          children.add(snoozeStrings(context));
        }

        return ElevatedButton(
          clipBehavior: Clip.antiAlias,
          style: buttonStyle,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) {
                return const SnoozeTimePage();
              }),
            );
          },
          child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: children),
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

  Widget snoozeStrings(BuildContext context) {
    return Container(
      width: 100,
      height: 40,
      alignment: Alignment.center,
      child: Text(
        AlarmAlertSettings().snoozeString(),
        style: labelLarge(context).copyWith(
          height: 0.6,
          fontSize: 40,
          color: Colors.black,
        ),
      ),
    );
  }
}
