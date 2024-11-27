import 'package:carer/models/details/status/status_service.dart';
import 'package:carer/services/platform_info_service.dart';
import 'package:carer/services/settings/alarm_alert_settings.dart';
import 'package:carer/services/themes_service.dart';
import 'package:carer/services/timer_service.dart';
import 'package:carer/utils/futures.dart';
import 'package:flutter/material.dart';

class StatusesBar extends StatelessWidget with ThemeMixin {
  const StatusesBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AWatch(
      (context) {
        List<Widget?> rowsMaybe = [
          getStatusIcon(context, Status.cannulaChange),
          getStatusIcon(context, Status.sensorChange),
          getStatusIcon(context, Status.notCharging),
          getStatusIcon(context, Status.powerLow),
          getStatusIcon(context, Status.silentOn),
          getStatusIcon(context, Status.lowReservoir),
          getStatusIcon(context, Status.disabledAlarms),
          getStatusIcon(context, Status.disabledAudioAlarms),
          getStatusIcon(context, Status.screenCanSleep),
        ];
        List<Widget> rows = rowsMaybe.whereType<Widget>().toList();

        if (rows.isEmpty) {
          return const SizedBox.shrink();
        }

        return Center(
          child: FittedBox(
            child: Container(
              padding: const EdgeInsets.all(4), // Add padding inside the border
              decoration: BoxDecoration(
                border: Border.all(
                  color: primaryColor(context), // Color of the border
                  width: 1, // Width of the border
                ),
                borderRadius: BorderRadius.circular(5), // Optional: if you want rounded corners
                color: backgroundColorShade(context),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: rows,
              ),
            ),
          ),
        );
      },
      dependencies: [
        ThemeService().themeSignal,
        AlarmAlertSettings().snoozeUntilSignal,
        TimerService().fiveSecondSignal,
        PlatformInfoService().ringerMode,
        PlatformInfoService().batteryMode,
      ],
      debugLabel: "StatusesBar",
    );
  }

  Widget? getStatusIcon(BuildContext context, Status status) {
    if (status.triggered()) {
      return Tooltip(
        message: status.reason,
        triggerMode: TooltipTriggerMode.tap,
        child: Icon(
          status.icon,
          color: primaryColor(context),
        ),
      );
    }
    return null;
  }
}
