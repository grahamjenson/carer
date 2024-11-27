import 'package:carer/models/details/status/status_service.dart';
import 'package:carer/services/settings/status_settings.dart';
import 'package:carer/services/themes_service.dart';
import 'package:carer/services/timer_service.dart';
import 'package:carer/services/ui/icons.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/widgets/smarttext.dart';
import 'package:flutter/material.dart';
import 'package:flutter_settings_ui/flutter_settings_ui.dart';

class StatusSettingsWidget extends AbstractSettingsSection with ThemeMixin {
  const StatusSettingsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return AWatch(
      (context) {
        List<SettingsTile?> tiles = [
          statusTile(context, Status.cannulaChange),
          cannulaAge(context),
          statusTile(context, Status.sensorChange),
          sensorAge(context),
          statusTile(context, Status.notCharging),
          statusTile(context, Status.powerLow),
          statusTile(context, Status.silentOn),
          statusTile(context, Status.lowReservoir),
          statusTile(context, Status.disabledAlarms),
          statusTile(context, Status.disabledAudioAlarms),
          statusTile(context, Status.screenCanSleep),
        ];

        List<SettingsTile> filteredTiles = tiles.whereType<SettingsTile>().toList();
        return SettingsSection(
          title: const Text('Status Settings'),
          tiles: filteredTiles,
        );
      },
      debugLabel: "StatusSettingsWidget",
      dependencies: [TimerService().fifteenSecondSignal],
    );
  }

  SettingsTile statusTile(BuildContext context, Status status) {
    Color? iconColor;
    if (status.triggered()) {
      iconColor = primaryColor(context);
    }
    var descriptionStyle = labelMedium(context).copyWith(color: onBackgroundColor(context));
    var statusStyle = labelSmall(context).copyWith(color: onBackgroundColor(context).dim);
    return SettingsTile.switchTile(
      initialValue: StatusSettings().statusEnabledContains(status.name),
      onToggle: (bool value) {
        if (value) {
          StatusSettings().statusEnabledAdd(status.name);
        } else {
          StatusSettings().statusEnabledRemove(status.name);
        }
      },
      descriptionInlineIos: true,
      title: Text(status.title),
      description: SmartText(texts: ["${status.description}\n", status.status], styles: [descriptionStyle, statusStyle]),
      leading: Icon(status.icon, color: iconColor),
    );
  }

  SettingsTile? cannulaAge(BuildContext context) {
    if (!StatusSettings().statusEnabledContains(Status.cannulaChange.name)) {
      return null;
    }

    return intSelector(
      context,
      "Cannula Max Age (Days)",
      () => StatusSettings().cannulaDays,
      () => StatusSettings().cannulaDays++,
      () => StatusSettings().cannulaDays--,
    );
  }

  SettingsTile? sensorAge(BuildContext context) {
    if (!StatusSettings().statusEnabledContains(Status.sensorChange.name)) {
      return null;
    }

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
              CarerIcons.SETTINGS_MINUS,
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
        InkWell(
          onTap: inc,
          child: const Icon(
            CarerIcons.SETTINGS_PLUS,
          ),
        ),
      ]),
    );
  }
}
