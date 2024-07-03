import 'package:carer/services/settings/alarm_settings.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/widgets/settings/alarms_pages/high_alarm_page.dart';
import 'package:carer/widgets/settings/alarms_pages/low_alarm_page.dart';
import 'package:carer/widgets/settings/togglebutton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_settings_ui/flutter_settings_ui.dart';

class AlarmsSettingsWidget extends AbstractSettingsSection {
  const AlarmsSettingsWidget({super.key});
  static const double _size = 50;

  static const TextStyle description = TextStyle(
    fontSize: 12,
    color: Colors.grey,
  );

  @override
  Widget build(BuildContext context) {
    return AWatch((context) {
      try {
        var tiles = [
          disableAlarms(context),
        ];

        if (!AlarmSettings().disableAlarms) {
          tiles = [
            disableAlarms(context),
            rangeAlarms(context),
            predictionAlarms(context),
            diffSettings(context),
            noDataAlarmSettings(),
          ];
        }
        return SettingsSection(
          title: const Text('Alarms'),
          tiles: tiles,
        );
      } catch (e) {
        print("Error in AlarmsSettingsWidget: $e");
        return const SizedBox();
      }
    });
  }

  SettingsTile disableAlarms(BuildContext context) {
    return SettingsTile.switchTile(
      title: const Text("Disable Alarms"),
      descriptionInlineIos: true,
      description: const Text(
        "Turn off all alarms",
        style: description,
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

  SettingsTile rangeAlarms(BuildContext context) {
    return SettingsTile(
      title: const Text("Range"),
      enabled: !AlarmSettings().disableAlarms,
      descriptionInlineIos: true,
      description: const Text(
        "Out of range",
        style: description,
      ),
      trailing: ToggleButtons(
        constraints: const BoxConstraints(maxHeight: _size, maxWidth: _size),
        renderBorder: true,
        borderRadius: BorderRadius.circular(10),
        borderWidth: 0,
        isSelected: [
          AlarmSettings().urgentLowAlarm,
          AlarmSettings().lowAlarm,
          AlarmSettings().highAlarm,
          AlarmSettings().urgentHighAlarm,
        ],
        onPressed: (int index) async {
          switch (index) {
            case 0:
              AlarmSettings().urgentLowAlarm = !AlarmSettings().urgentLowAlarm;
              break;
            case 1:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LowAlarmPage()),
              );
              break;
            case 2:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HighAlarmPage()),
              );
              break;
            case 3:
              AlarmSettings().urgentHighAlarm = !AlarmSettings().urgentHighAlarm;
              break;
          }
        },
        children: [
          const ToggleButton(
            text: "Urgent Low",
            height: _size,
            width: _size,
          ),
          ToggleButton(
            text: "Low\n${AlarmSettings().lowMinutes}m",
            height: _size,
            width: _size,
            icon: Icons.more_vert,
          ),
          ToggleButton(
            text: "High\n${AlarmSettings().highMinutes}m",
            height: _size,
            width: _size,
            icon: Icons.more_vert,
          ),
          const ToggleButton(
            text: "Urgent High",
            height: _size,
            width: _size,
          ),
        ],
      ),
    );
  }

  SettingsTile diffSettings(BuildContext context) {
    return SettingsTile(
      title: const Text("Rise/Drop"),
      descriptionInlineIos: true,
      description: const Text(
        "Rising or dropping quickly",
        style: description,
      ),
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
              icon: Icons.more_vert,
              onLongPress: () async {
                var minutes =
                    await alertDialogOfButtons<int>(context, "Alert Dropping for:", ["5m", "10m", "15m", "20m", "30m"], [5, 10, 15, 20, 30]);
                AlarmSettings().fastDropAlarmMinutes = minutes;
              }),
          ToggleButton(
            text: "Fast Rise\n${AlarmSettings().fastRiseAlarmMinutes}m",
            icon: Icons.more_vert,
            height: _size,
            width: _size,
            onLongPress: () async {
              var minutes = await alertDialogOfButtons<int>(context, "Alert Rising for:", ["5m", "10m", "15m", "20m", "30m"], [5, 10, 15, 20, 30]);
              AlarmSettings().fastRiseAlarmMinutes = minutes;
            },
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

  SettingsTile predictionAlarms(BuildContext context) {
    return SettingsTile(
      title: const Text("Prediciton alarms"),
      descriptionInlineIos: true,
      trailing: ToggleButtons(
          constraints: const BoxConstraints(maxHeight: _size, maxWidth: _size),
          renderBorder: true,
          borderRadius: BorderRadius.circular(10),
          borderWidth: 0,
          isSelected: [
            AlarmSettings().lowPredictionAlarm,
          ],
          onPressed: (int index) {
            switch (index) {
              case 0:
                AlarmSettings().lowPredictionAlarm = !AlarmSettings().lowPredictionAlarm;
                break;
            }
          },
          children: [
            ToggleButton(
                text: "Low\n${AlarmSettings().lowPredictionMinutes}m",
                height: _size,
                width: _size,
                icon: Icons.more_vert,
                onLongPress: () async {
                  var lowMinutes =
                      await alertDialogOfButtons<int>(context, "Alert Low for:", ["0m", "5m", "10m", "15m", "20m", "30m"], [0, 5, 10, 15, 20, 30]);
                  AlarmSettings().lowPredictionMinutes = lowMinutes;
                }),
          ]),
    );
  }
}
