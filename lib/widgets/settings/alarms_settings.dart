import 'dart:math';

import 'package:carer/services/alarms_service.dart';
import 'package:carer/services/settings/alarm_alert_settings.dart';
import 'package:carer/services/settings/alarm_settings.dart';
import 'package:carer/widgets/colours.dart';
import 'package:carer/widgets/settings/alarms_pages/high_alarm_page.dart';
import 'package:carer/widgets/settings/alarms_pages/low_alarm_page.dart';
import 'package:carer/widgets/settings/togglebutton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_settings_ui/flutter_settings_ui.dart';
import 'package:signals/signals_flutter.dart';

class AlarmsSettingsWidget extends AbstractSettingsSection {
  const AlarmsSettingsWidget({super.key});
  static const double _size = 50;

  static const TextStyle description = TextStyle(
    fontSize: 12,
    color: Colors.grey,
  );

  @override
  Widget build(BuildContext context) {
    return Watch((_) {
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
            predictiveSnooze(),
            SettingsTile(title: const Divider()),
            volumeOverride(context),
            volumeSettings(context),
            progressiveVolume(context),
            alarmFileSelect(),
            testAlert(context),
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

  SettingsTile predictiveSnooze() {
    return SettingsTile.switchTile(
      title: const Text("Smart Snooze"),
      descriptionInlineIos: true,
      description: const Text(
        "Ignore when  good direction",
        style: description,
      ),
      initialValue: AlarmAlertSettings().smartSnooze,
      onToggle: (bool value) {
        AlarmAlertSettings().smartSnooze = value;
      },
    );
  }

  SettingsTile volumeOverride(BuildContext context) {
    return SettingsTile.switchTile(
      title: const Text("Volume Override"),
      initialValue: AlarmAlertSettings().volumeOveride,
      onToggle: (bool value) {
        AlarmAlertSettings().volumeOveride = value;
      },
    );
  }

  SettingsTile volumeSettings(BuildContext context) {
    int minRange = 0;
    int maxRange = 100;
    double width = MediaQuery.of(context).size.width;

    var color = mainColor;
    if (!AlarmAlertSettings().volumeOveride) {
      color = Colors.grey;
    }

    ValueChanged<double>? sliderCallback = (double value) => AlarmAlertSettings().volumeOverrideValue = value.toInt();

    if (!AlarmAlertSettings().volumeOveride) {
      sliderCallback = null;
    }

    return SettingsTile(
        enabled: AlarmAlertSettings().volumeOveride,
        title: const Text(""),
        trailing: SizedBox(
          width: width - 80,
          child: Row(
            children: [
              Expanded(
                  flex: 1,
                  child: InkWell(
                      child: Icon(Icons.volume_down, color: color),
                      onTap: () {
                        var ov = AlarmAlertSettings().volumeOverrideValuePeek;
                        AlarmAlertSettings().volumeOverrideValue = max(minRange, ov - 10).toInt();
                      })),
              Expanded(
                  flex: 12,
                  child: Container(
                      alignment: Alignment.center,
                      height: 20,
                      child: Slider(
                        divisions: 50,
                        value: AlarmAlertSettings().volumeOverrideValue.toDouble(),
                        min: 0,
                        max: 100,
                        onChanged: sliderCallback,
                      ))),
              Expanded(
                flex: 1,
                child: InkWell(
                  child: Icon(
                    Icons.volume_up,
                    color: color,
                  ),
                  onTap: () {
                    var ov = AlarmAlertSettings().volumeOverrideValuePeek;
                    AlarmAlertSettings().volumeOverrideValue = min(maxRange, ov + 10).toInt();
                  },
                ),
              ),
            ],
          ),
        ));
  }

  SettingsTile progressiveVolume(BuildContext context) {
    return SettingsTile(
      title: const Text("Volume Progression"),
      trailing: ToggleButtons(
        constraints: const BoxConstraints(maxHeight: 40, maxWidth: 40),
        renderBorder: true,
        borderRadius: BorderRadius.circular(10),
        borderWidth: 4,
        isSelected: [
          10 == AlarmAlertSettings().volumeProgressionSeconds,
          20 == AlarmAlertSettings().volumeProgressionSeconds,
          30 == AlarmAlertSettings().volumeProgressionSeconds,
          60 == AlarmAlertSettings().volumeProgressionSeconds,
          120 == AlarmAlertSettings().volumeProgressionSeconds,
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
            case 3:
              value = 60;
              break;
            case 4:
              value = 120;
              break;
          }
          if (AlarmAlertSettings().volumeProgressionSeconds == value) {
            value = -1; // disable
          }
          AlarmAlertSettings().volumeProgressionSeconds = value;
        },
        children: const [
          ToggleButton(
            text: "10s",
            height: _size,
            width: _size,
          ),
          ToggleButton(
            text: "20s",
            height: _size,
            width: _size,
          ),
          ToggleButton(
            text: "30s",
            height: _size,
            width: _size,
          ),
          ToggleButton(
            text: "1m",
            height: _size,
            width: _size,
          ),
          ToggleButton(
            text: "2m",
            height: _size,
            width: _size,
          ),
        ],
      ),
    );
  }

  SettingsTile alarmFileSelect() {
    return SettingsTile(
      title: const Text("Alarm Sound"),
      descriptionInlineIos: true,
      trailing: ToggleButtons(
        constraints: const BoxConstraints(
          maxHeight: _size,
          maxWidth: _size * 1.5,
        ),
        renderBorder: true,
        borderRadius: BorderRadius.circular(10),
        borderWidth: 4,
        isSelected: [
          AlarmAlertSettings().alarmAsset == AlarmSounds.nightguard,
          AlarmAlertSettings().alarmAsset == AlarmSounds.letsgo,
          AlarmAlertSettings().alarmAsset == AlarmSounds.hybridas,
        ],
        onPressed: (int index) {
          switch (index) {
            case 0:
              AlarmAlertSettings().alarmAsset = AlarmSounds.nightguard;
              break;
            case 1:
              AlarmAlertSettings().alarmAsset = AlarmSounds.letsgo;
              break;
            case 2:
              AlarmAlertSettings().alarmAsset = AlarmSounds.hybridas;
              break;
          }
        },
        children: const [
          ToggleButton(
            text: "NightGuard",
            height: _size,
            width: _size * 1.5,
          ),
          ToggleButton(
            text: "Lets Go",
            height: _size,
            width: _size * 1.5,
          ),
          ToggleButton(
            text: "Hybridas",
            height: _size,
            width: _size * 1.5,
          ),
        ],
      ),
    );
  }

  SettingsTile testAlert(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    String text = "Test Alarm";
    if (AlarmsService().testAlarmPlaying) {
      text = "Stop Test";
    }

    return SettingsTile(
        title: const Text(""),
        trailing: SizedBox(
            width: width - 100,
            child: Center(
              child: ElevatedButton(
                onPressed: () async {
                  await AlarmsService().testAlarm();
                },
                child: Text(text),
              ),
            )));
  }
}
