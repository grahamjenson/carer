import 'package:carer/services/alarms/alarms.dart';
import 'package:carer/services/settings/alarm_alert_settings.dart';
import 'package:carer/services/settings/alarm_settings.dart';
import 'package:carer/services/settings/target_settings.dart';
import 'package:carer/services/settings/ui_settings.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/widgets/settings/alarms_pages/battery_alarm_page.dart';
import 'package:carer/widgets/settings/alarms_pages/fast_fall_alarm_page.dart';
import 'package:carer/widgets/settings/alarms_pages/fast_rise_alarm_page.dart';
import 'package:carer/widgets/settings/alarms_pages/high_alarm_page.dart';
import 'package:carer/widgets/settings/alarms_pages/low_alarm_page.dart';
import 'package:carer/widgets/settings/alarms_pages/no_data_alarm_page.dart';
import 'package:carer/widgets/settings/alarms_pages/urgent_high_alarm_page.dart';
import 'package:carer/widgets/settings/alarms_pages/urgent_low_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_settings_ui/flutter_settings_ui.dart';

class AlarmsSettingsWidget extends AbstractSettingsSection {
  const AlarmsSettingsWidget({super.key});
  static const double _size = 50;

  @override
  Widget build(BuildContext context) {
    return AWatch(
      (context) {
        var tiles = [
          disableAlarms(context),
        ];

        if (!AlarmSettings().disableAlarms) {
          tiles = [
            disableAlarms(context),
            urgentLowAlarm(context),
            lowAlarm(context),
            highAlarm(context),
            urgentHighAlarm(context),
            fastRiseSettings(context),
            fastFallSettings(context),
            noDataAlarmSettings(),
            batteryAlarms(),
          ];
        }
        return SettingsSection(
          title: const Text('Alarms'),
          tiles: tiles,
        );
      },
      debugLabel: "AlarmsSettingsWidget",
      dependencies: AlarmSettings().allSignals() + TargetSettings().allSignals() + AlarmAlertSettings().allSignals(),
    );
  }

  SettingsTile urgentLowAlarm(BuildContext context) {
    var unit = UISettings().unit;
    String description = "Alarm Below ${unit.str(TargetSettings().lowUrgent)}";
    if (!AlarmSettings().urgentLowAlarm) {
      description = "Off";
    }

    return SettingsTile.navigation(
      title: const Text("Urgent Low Alarm"),
      leading: Icon(AlarmType.urgentLow.icon),
      description: Text(description),
      descriptionInlineIos: true,
      onPressed: (context) => Navigator.push(context, MaterialPageRoute(builder: (context) => const UrgentAlarmLowSettingsPage())),
    );
  }

  SettingsTile lowAlarm(BuildContext context) {
    var unit = UISettings().unit;
    String description = "Alarm Below ${unit.str(TargetSettings().lowTarget)}";
    if (AlarmSettings().lowPredictionAlarm) {
      description += " (w/ Predictive Low in ${AlarmSettings().lowPredictionMinutes}m)";
    }
    if (!AlarmSettings().lowAlarm) {
      description = "Off";
    }

    return SettingsTile.navigation(
      title: const Text("Low Alarm"),
      leading: Icon(AlarmType.low.icon),
      description: Text(description),
      descriptionInlineIos: true,
      onPressed: (context) => Navigator.push(context, MaterialPageRoute(builder: (context) => const LowAlarmSettingsPage())),
    );
  }

  SettingsTile highAlarm(BuildContext context) {
    var unit = UISettings().unit;
    String description = "Alarm Above ${unit.str(TargetSettings().highTarget)}";
    if (AlarmSettings().highMinutes > 0) {
      description += " for ${AlarmSettings().highMinutes}m";
    }
    if (AlarmAlertSettings().smartSnoozeHigh) {
      description += " (w/ Smart Snooze)";
    }
    if (!AlarmSettings().highAlarm) {
      description = "Off";
    }

    return SettingsTile.navigation(
      title: const Text("High Alarm"),
      leading: Icon(AlarmType.high.icon),
      description: Text(description),
      descriptionInlineIos: true,
      onPressed: (context) => Navigator.push(context, MaterialPageRoute(builder: (context) => const HighAlarmSettingsPage())),
    );
  }

  SettingsTile urgentHighAlarm(BuildContext context) {
    var unit = UISettings().unit;
    String description = "Alarm Above ${unit.str(TargetSettings().highUrgent)}";
    if (!AlarmSettings().urgentHighAlarm) {
      description = "Off";
    }

    return SettingsTile.navigation(
      title: const Text("Urgent High Alarm"),
      leading: Icon(AlarmType.urgentHigh.icon),
      description: Text(description),
      descriptionInlineIos: true,
      onPressed: (context) => Navigator.push(context, MaterialPageRoute(builder: (context) => const UrgentAlarmHighSettingsPage())),
    );
  }

  SettingsTile fastFallSettings(BuildContext context) {
    var description = "Fast Drop Alarm after ${AlarmSettings().fastDropAlarmMinutes}m";
    if (AlarmSettings().fastDropAlarmMinutes < 0) {
      description = "Off";
    }

    return SettingsTile.navigation(
      title: const Text("Fast Drop Alarm"),
      leading: Icon(AlarmType.fastDrop.icon),
      description: Text(description),
      descriptionInlineIos: true,
      onPressed: (context) => Navigator.push(context, MaterialPageRoute(builder: (context) => const FastFallAlarmSettingsPage())),
    );
  }

  SettingsTile fastRiseSettings(BuildContext context) {
    var description = "Fast Rise Alarm after ${AlarmSettings().fastRiseAlarmMinutes}m";
    if (AlarmSettings().fastRiseAlarmMinutes < 0) {
      description = "Off";
    }

    return SettingsTile.navigation(
      title: const Text("Fast Rise Alarm"),
      leading: Icon(AlarmType.fastRise.icon),
      description: Text(description),
      descriptionInlineIos: true,
      onPressed: (context) => Navigator.push(context, MaterialPageRoute(builder: (context) => const FastRiseAlarmSettingsPage())),
    );
  }

  SettingsTile disableAlarms(BuildContext context) {
    return SettingsTile.switchTile(
      title: const Text("Disable Alarms"),
      descriptionInlineIos: true,
      description: const Text(
        "Turn off all alarms",
      ),
      initialValue: AlarmSettings().disableAlarms,
      onToggle: (bool disable) async {
        if (!disable) {
          AlarmSettings().disableAlarms = false;
          return;
        }
        // show the dialog
        bool? areYouSure = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            Widget cancelButton = TextButton(
              child: const Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            );
            Widget disableButton = TextButton(
              child: const Text("Disable"),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            );

            // set up the AlertDialog
            return AlertDialog(
              title: const Text("Disable Alarms"),
              content: const Text("Disable all alarms (not recommended)?"),
              actions: [
                cancelButton,
                disableButton,
              ],
            );
          },
        );
        if (areYouSure == true) {
          AlarmSettings().disableAlarms = true;
        }
      },
    );
  }

  SettingsTile noDataAlarmSettings() {
    var description = "No Data Alarm after ${AlarmSettings().noDataAlarmMinutes}m";
    if (AlarmSettings().noDataAlarmMinutes < 0) {
      description = "Off";
    }

    return SettingsTile.navigation(
      title: const Text("No Data Alarm"),
      leading: Icon(AlarmType.noData.icon),
      description: Text(description),
      descriptionInlineIos: true,
      onPressed: (context) => Navigator.push(context, MaterialPageRoute(builder: (context) => const NoDataAlarmSettingsPage())),
    );
  }

  SettingsTile batteryAlarms() {
    String description = "Battery below 10%(";
    List<String> phones = [];
    if (AlarmSettings().t1dBatteryAlarm) {
      phones.add("T1D Phone");
    }
    if (AlarmSettings().carerBatteryAlarm) {
      phones.add("This Phone");
    }
    description += "${phones.join(", ")})";

    if (!AlarmSettings().t1dBatteryAlarm && !AlarmSettings().carerBatteryAlarm) {
      description = "Off";
    }

    return SettingsTile.navigation(
      title: const Text("Low Battery Alarm"),
      leading: Icon(AlarmType.lowBattery.icon),
      description: Text(description),
      descriptionInlineIos: true,
      onPressed: (context) => Navigator.push(context, MaterialPageRoute(builder: (context) => const BatteryAlarmSettingsPage())),
    );
  }
}
