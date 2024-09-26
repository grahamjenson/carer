import 'package:carer/services/alarms/alarms.dart';
import 'package:carer/services/settings/alarm_alert_settings.dart';
import 'package:carer/services/settings/alarm_settings.dart';
import 'package:carer/services/settings/target_settings.dart';
import 'package:carer/services/settings/ui_settings.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/widgets/settings/alarms_pages/diff_alarm_page.dart';
import 'package:carer/widgets/settings/alarms_pages/high_alarm_page.dart';
import 'package:carer/widgets/settings/alarms_pages/low_alarm_page.dart';
import 'package:carer/widgets/settings/alarms_pages/urgent_high_alarm_page.dart';
import 'package:carer/widgets/settings/alarms_pages/urgent_low_page.dart';
import 'package:carer/widgets/settings/togglebutton.dart';
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
            diffSettings(context),
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
      leading: Icon(Alarm.urgentLow.icon),
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
      leading: Icon(Alarm.low.icon),
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
      leading: Icon(Alarm.high.icon),
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
      leading: Icon(Alarm.urgentHigh.icon),
      description: Text(description),
      descriptionInlineIos: true,
      onPressed: (context) => Navigator.push(context, MaterialPageRoute(builder: (context) => const UrgentAlarmHighSettingsPage())),
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

  SettingsTile diffSettings(BuildContext context) {
    return SettingsTile.navigation(
      title: const Text("Rise/Drop"),
      onPressed: (context) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const DiffAlarmPage()),
        );
      },
      descriptionInlineIos: true,
      description: const Text("Rising or dropping quickly"),
      trailing: ToggleButtons(
        constraints: const BoxConstraints(maxHeight: _size, maxWidth: _size),
        renderBorder: true,
        borderRadius: BorderRadius.circular(10),
        borderWidth: 0,
        isSelected: [
          AlarmSettings().fastDropAlarm,
          AlarmSettings().fastRiseAlarm,
        ],
        onPressed: (int index) {
          switch (index) {
            case 0:
              AlarmSettings().fastDropAlarm = !AlarmSettings().fastDropAlarmPeek;
              break;
            case 1:
              AlarmSettings().fastRiseAlarm = !AlarmSettings().fastRiseAlarmPeek;
              break;
          }
        },
        children: [
          ToggleButton(
            height: _size,
            width: _size,
            text: "Fast Drop\n${AlarmSettings().fastDropAlarmMinutes}m",
          ),
          ToggleButton(
            text: "Fast Rise\n${AlarmSettings().fastRiseAlarmMinutes}m",
            height: _size,
            width: _size,
          ),
        ],
      ),
    );
  }

  SettingsTile noDataAlarmSettings() {
    return SettingsTile(
      title: const Text("No Data"),
      trailing: ToggleButtons(
        constraints: const BoxConstraints(maxHeight: _size, maxWidth: _size),
        renderBorder: true,
        borderRadius: BorderRadius.circular(10),
        borderWidth: 0,
        isSelected: [
          10 == AlarmSettings().noDataAlarmMinutes,
          20 == AlarmSettings().noDataAlarmMinutes,
          30 == AlarmSettings().noDataAlarmMinutes,
        ],
        onPressed: (int index) {
          var value = -1;
          switch (index) {
            case 0:
              value = 10;
              break;
            case 1:
              value = 20;
              break;
            case 2:
              value = 30;
              break;
          }
          if (value == AlarmSettings().noDataAlarmMinutes) {
            value = -1; // disable
          }
          AlarmSettings().noDataAlarmMinutes = value;
        },
        children: const [
          ToggleButton(
            text: "10m",
            height: _size,
            width: _size,
          ),
          ToggleButton(
            text: "20m",
            height: _size,
            width: _size,
          ),
          ToggleButton(
            text: "30m",
            height: _size,
            width: _size,
          ),
        ],
      ),
    );
  }

  SettingsTile batteryAlarms() {
    return SettingsTile(
      title: const Text("Low Battery Alarm"),
      trailing: ToggleButtons(
        constraints: const BoxConstraints(maxHeight: _size, maxWidth: _size * 2),
        renderBorder: true,
        borderRadius: BorderRadius.circular(10),
        borderWidth: 0,
        isSelected: [
          AlarmSettings().carerBatteryAlarm,
          AlarmSettings().t1dBatteryAlarm,
        ],
        onPressed: (int index) {
          switch (index) {
            case 0:
              AlarmSettings().carerBatteryAlarm = !AlarmSettings().carerBatteryAlarm;
              break;
            case 1:
              AlarmSettings().t1dBatteryAlarm = !AlarmSettings().t1dBatteryAlarm;
              break;
          }
        },
        children: const [
          ToggleButton(
            text: "Carer Phone\n< 30%",
            height: _size,
            width: _size * 1.5,
          ),
          ToggleButton(
            text: "T1D Phone\n< 30%",
            height: _size,
            width: _size * 1.5,
          ),
        ],
      ),
    );
  }
}
