import 'dart:math';

import 'package:carer/models/alarms_cn.dart';
import 'package:carer/models/settings/alarm_settings.dart';
import 'package:carer/models/settings_cn.dart';
import 'package:carer/widgets/colours.dart';
import 'package:carer/widgets/settings/togglebutton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_settings_ui/flutter_settings_ui.dart';
import 'package:provider/provider.dart';

class AlarmsSettingsWidget extends AbstractSettingsSection {
  const AlarmsSettingsWidget({super.key});
  static const double _size = 50;

  static const TextStyle description = TextStyle(
    fontSize: 12,
    color: Colors.grey,
  );

  @override
  Widget build(BuildContext context) {
    return Consumer2<Settings, AlarmsCN>(
        builder: (context, settings, alarms, child) {
      var alarmSettings = settings.alarmSettings;
      return SettingsSection(
        title: const Text('Alarms (Long Press for info and settings)'),
        tiles: [
          targetSettings(context, alarmSettings),
          diffSettings(context, alarmSettings),
          noDataAlarmSettings(alarmSettings),
          predictionAlarms(alarmSettings),
          predictiveSnooze(alarmSettings),
          SettingsTile(title: const Divider()),
          volumeOverride(context, alarmSettings),
          volumeSettings(context, alarmSettings),
          progressiveVolume(context, alarmSettings),
          alarmFileSelect(alarmSettings),
          testAlert(context, alarmSettings, alarms),
        ],
      );
    });
  }

  SettingsTile targetSettings(BuildContext context, AlarmSettings settings) {
    return SettingsTile(
      title: const Text("Range"),
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
          settings.urgentLowAlarm,
          settings.lowAlarm,
          settings.highAlarm,
          settings.urgentHighAlarm,
        ],
        onPressed: (int index) async {
          switch (index) {
            case 0:
              settings.urgentLowAlarm = !settings.urgentLowAlarm;
              break;
            case 1:
              settings.lowAlarm = !settings.lowAlarm;
              break;
            case 2:
              settings.highAlarm = !settings.highAlarm;
              break;
            case 3:
              settings.urgentHighAlarm = !settings.urgentHighAlarm;
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
              text: "Low\n${settings.lowMinutes}m",
              height: _size,
              width: _size,
              icon: Icons.touch_app_outlined,
              onLongPress: () async {
                var lowMinutes = await alertDialogOfButtons<int>(context,
                    "Alert Low for:", ["15m", "20m", "30m"], [15, 20, 30]);
                settings.lowMinutes = lowMinutes;
              }),
          ToggleButton(
              text: "High\n${settings.highMinutes}m",
              height: _size,
              width: _size,
              icon: Icons.touch_app_outlined,
              onLongPress: () async {
                var highMinutes = await alertDialogOfButtons<int>(context,
                    "Alert High for:", ["15m", "20m", "30m"], [15, 20, 30]);
                settings.highMinutes = highMinutes;
              }),
          const ToggleButton(
            text: "Urgent High",
            height: _size,
            width: _size,
          ),
        ],
      ),
    );
  }

  SettingsTile diffSettings(BuildContext context, AlarmSettings settings) {
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
          settings.fastDropAlarm,
          settings.fastRiseAlarm,
        ],
        onPressed: (int index) {
          switch (index) {
            case 0:
              settings.fastDropAlarm = !settings.fastDropAlarm;
              break;
            case 1:
              settings.fastRiseAlarm = !settings.fastRiseAlarm;
              break;
          }
        },
        children: [
          ToggleButton(
              height: _size,
              width: _size,
              text: "Fast Drop\n${settings.fastDropAlarmMinutes}m",
              icon: Icons.touch_app_outlined,
              onLongPress: () async {
                var minutes = await alertDialogOfButtons<int>(context,
                    "Alert Dropping for:", ["15m", "20m", "30m"], [15, 20, 30]);
                settings.fastDropAlarmMinutes = minutes;
              }),
          ToggleButton(
            text: "Fast Rise\n${settings.fastRiseAlarmMinutes}m",
            icon: Icons.touch_app_outlined,
            height: _size,
            width: _size,
            onLongPress: () async {
              var minutes = await alertDialogOfButtons<int>(context,
                  "Alert Rising for:", ["15m", "20m", "30m"], [15, 20, 30]);
              settings.fastRiseAlarmMinutes = minutes;
            },
          ),
        ],
      ),
    );
  }

  SettingsTile noDataAlarmSettings(AlarmSettings settings) {
    return SettingsTile(
      title: const Text("No Data"),
      trailing: ToggleButtons(
        constraints: const BoxConstraints(maxHeight: _size, maxWidth: _size),
        renderBorder: true,
        borderRadius: BorderRadius.circular(10),
        borderWidth: 0,
        isSelected: [
          10 == settings.noDataAlarmMinutes,
          20 == settings.noDataAlarmMinutes,
          30 == settings.noDataAlarmMinutes,
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
          if (value == settings.noDataAlarmMinutes) {
            value = -1; // disable
          }
          settings.noDataAlarmMinutes = value;
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

  SettingsTile predictionAlarms(AlarmSettings settings) {
    return SettingsTile(
      title: const Text("Prediction"),
      descriptionInlineIos: true,
      description: const Text(
        "Predicted out of range",
        style: description,
      ),
      trailing: ToggleButtons(
        constraints: const BoxConstraints(maxHeight: _size, maxWidth: _size),
        renderBorder: true,
        borderRadius: BorderRadius.circular(10),
        borderWidth: 0,
        isSelected: [
          settings.predictionAlgorithm == PredictionAlgorithm.simple,
          settings.predictionAlgorithm == PredictionAlgorithm.profile,
        ],
        onPressed: (int index) {
          PredictionAlgorithm value = PredictionAlgorithm.none;
          switch (index) {
            case 0:
              value = PredictionAlgorithm.simple;
              break;
            case 1:
              value = PredictionAlgorithm.profile;
              break;
          }
          if (value == settings.predictionAlgorithm) {
            value = PredictionAlgorithm.none; // disable
          }
          settings.predictionAlgorithm = value;
        },
        children: const [
          ToggleButton(
            text: "Simple",
            height: _size,
            width: _size,
          ),
          ToggleButton(
            text: "Profile",
            height: _size,
            width: _size,
          ),
          // ToggleButton(text: "Smart Model 1", ),
          // ToggleButton(text: "Smart Model 2", ),
        ],
      ),
    );
  }

  SettingsTile predictiveSnooze(AlarmSettings settings) {
    return SettingsTile(
      title: const Text("Predictive Snooze"),
      descriptionInlineIos: true,
      description: const Text(
        "Snooze if predicted to recover",
        style: description,
      ),
      trailing: ToggleButtons(
        constraints: const BoxConstraints(maxHeight: _size, maxWidth: _size),
        renderBorder: true,
        borderRadius: BorderRadius.circular(10),
        borderWidth: 0,
        isSelected: [
          settings.predictiveSnooze == PredictionAlgorithm.simple,
          settings.predictiveSnooze == PredictionAlgorithm.profile,
        ],
        onPressed: (int index) {
          PredictionAlgorithm value = PredictionAlgorithm.none;
          switch (index) {
            case 0:
              value = PredictionAlgorithm.simple;
              break;
            case 1:
              value = PredictionAlgorithm.profile;
              break;
          }
          if (value == settings.predictiveSnooze) {
            value = PredictionAlgorithm.none; // disable
          }
          settings.predictiveSnooze = value;
        },
        children: const [
          ToggleButton(
            text: "Simple",
            height: _size,
            width: _size,
          ),
          ToggleButton(
            text: "Profile",
            height: _size,
            width: _size,
          ),
          // ToggleButton(text: "Smart Model 2", ),
        ],
      ),
    );
  }

  SettingsTile volumeOverride(BuildContext context, AlarmSettings settings) {
    return SettingsTile.switchTile(
      title: const Text("Volume Override"),
      initialValue: settings.volumeOveride,
      onToggle: (bool value) {
        settings.volumeOveride = value;
      },
    );
  }

  SettingsTile volumeSettings(BuildContext context, AlarmSettings settings) {
    int minRange = 0;
    int maxRange = 100;
    double width = MediaQuery.of(context).size.width;

    var color = mainColor;
    if (!settings.volumeOveride) {
      color = Colors.grey;
    }

    ValueChanged<double>? sliderCallback =
        (double value) => settings.volumeOverrideValue = value.toInt();

    if (!settings.volumeOveride) {
      sliderCallback = null;
    }

    return SettingsTile(
        enabled: settings.volumeOveride,
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
                        settings.volumeOverrideValue =
                            max(minRange, settings.volumeOverrideValue - 10)
                                .toInt();
                      })),
              Expanded(
                  flex: 12,
                  child: Container(
                      alignment: Alignment.center,
                      height: 20,
                      child: Slider(
                        divisions: 50,
                        value: settings.volumeOverrideValue.toDouble(),
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
                    settings.volumeOverrideValue = min(maxRange,
                            settings.volumeOverrideValue.toDouble() + 10)
                        .toInt();
                  },
                ),
              ),
            ],
          ),
        ));
  }

  SettingsTile progressiveVolume(BuildContext context, AlarmSettings settings) {
    return SettingsTile(
      title: const Text("Volume Progression"),
      trailing: ToggleButtons(
        constraints: const BoxConstraints(maxHeight: 40, maxWidth: 40),
        renderBorder: true,
        borderRadius: BorderRadius.circular(10),
        borderWidth: 4,
        isSelected: [
          10 == settings.volumeProgressionSeconds,
          20 == settings.volumeProgressionSeconds,
          30 == settings.volumeProgressionSeconds,
          60 == settings.volumeProgressionSeconds,
          120 == settings.volumeProgressionSeconds,
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
          if (settings.volumeProgressionSeconds == value) {
            value = -1; // disable
          }
          settings.volumeProgressionSeconds = value;
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

  SettingsTile alarmFileSelect(AlarmSettings settings) {
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
          settings.alarmAsset == AlarmSounds.nightguard,
          settings.alarmAsset == AlarmSounds.letsgo,
          settings.alarmAsset == AlarmSounds.hybridas,
        ],
        onPressed: (int index) {
          PredictionAlgorithm value = PredictionAlgorithm.none;
          switch (index) {
            case 0:
              settings.alarmAsset = AlarmSounds.nightguard;
              break;
            case 1:
              settings.alarmAsset = AlarmSounds.letsgo;
              break;
            case 2:
              settings.alarmAsset = AlarmSounds.hybridas;
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

  SettingsTile testAlert(
      BuildContext context, AlarmSettings settings, AlarmsCN alarms) {
    double width = MediaQuery.of(context).size.width;

    String text = "Test Alarm";
    if (settings.testAlarmPlaying) {
      text = "Stop Test";
    }

    return SettingsTile(
        title: const Text(""),
        trailing: SizedBox(
            width: width - 100,
            child: Center(
              child: ElevatedButton(
                onPressed: () async {
                  await alarms.testAlarm();
                },
                child: Text(text),
              ),
            )));
  }
}
