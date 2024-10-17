import 'package:carer/services/settings/status_settings.dart';
import 'package:carer/services/status_service.dart';
import 'package:carer/services/themes_service.dart';
import 'package:carer/services/timer_service.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/widgets/smarttext.dart';
import 'package:flutter/material.dart';
import 'package:flutter_settings_ui/flutter_settings_ui.dart';
import 'package:unicons/unicons.dart';

class StatusSettingsWidget extends AbstractSettingsSection with ThemeMixin {
  const StatusSettingsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return AWatch(
      (context) {
        List<SettingsTile> tiles = [
          inactiveStatus(context, Status.cannulaChange),
          cannulaAge(context),
          inactiveStatus(context, Status.sensorChange),
          sensorAge(context),
          inactiveStatus(context, Status.notCharging),
          inactiveStatus(context, Status.powerLow),
          inactiveStatus(context, Status.silentOn),
        ];

        return SettingsSection(
          title: const Text('Status Settings'),
          tiles: tiles,
        );
      },
      debugLabel: "StatusSettingsWidget",
      dependencies: [TimerService().fifteenSecondSignal],
    );
  }

  SettingsTile inactiveStatus(BuildContext context, Status status) {
    Color? iconColor;
    if (status.triggered()) {
      iconColor = primaryColor(context);
    }
    var descriptionStyle = labelMedium(context).copyWith(color: onBackgroundColor(context));
    var statusStyle = labelSmall(context).copyWith(color: onBackgroundColor(context).dim);
    return SettingsTile(
      descriptionInlineIos: true,
      title: Text(status.title),
      description: SmartText(texts: ["${status.description}\n", status.status], styles: [descriptionStyle, statusStyle]),
      leading: Icon(status.icon, color: iconColor),
    );
  }

  SettingsTile cannulaAge(BuildContext context) {
    return intSelector(
      context,
      "Cannula Max Age (Days)",
      () => StatusSettings().cannulaDays,
      () => StatusSettings().cannulaDays++,
      () => StatusSettings().cannulaDays--,
    );
  }

  SettingsTile sensorAge(BuildContext context) {
    return intSelector(
      context,
      "Sensor Max Age (Days)",
      () => StatusSettings().sensorDays,
      () => StatusSettings().sensorDays++,
      () => StatusSettings().sensorDays--,
    );
  }

  SettingsTile intSelector(BuildContext context, String title, Function getInt, GestureTapCallback inc, GestureTapCallback dec) {
    return SettingsTile(
      title: Text(
        title,
        style: labelMedium(context).copyWith(color: onBackgroundColor(context)),
        textAlign: TextAlign.end,
      ),
      trailing: Row(children: [
        InkWell(
            onTap: dec,
            child: const Icon(
              UniconsLine.minus,
            )),
        SizedBox(
            width: 50,
            child: InkWell(
              borderRadius: BorderRadius.circular(8), // Match the border radius
              splashColor: Colors.blueAccent.withOpacity(0.3), // Splash color
              highlightColor: Colors.blueAccent.withOpacity(0.1), // Highlight color

              child: Text(
                getInt().toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ), // Add padding inside the border
            )),
        InkWell(onTap: inc, child: const Icon(UniconsLine.plus)),
      ]),
    );
  }
}
