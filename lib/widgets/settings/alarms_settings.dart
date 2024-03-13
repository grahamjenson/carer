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
          volumeSettings(context, alarmSettings),
          progressiveVolume(context, alarmSettings),
          testAlert(context, alarms),
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
        children: const [
          ToggleButton(
            text: "Urgent Low",
            height: _size,
            width: _size,
          ),
          ToggleButton(
            text: "Low",
            height: _size,
            width: _size,
          ),
          ToggleButton(
            text: "High",
            height: _size,
            width: _size,
          ),
          ToggleButton(
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
              onLongPress: () async {
                var x = await alertDialogOfButtons<int>(context,
                    "Alert Dropping for:", ["15m", "20m", "30m"], [15, 20, 30]);
                settings.fastDropAlarmMinutes = x;
              }),
          const ToggleButton(
            text: "Fast Rise",
            height: _size,
            width: _size,
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

  SettingsTile volumeSettings(BuildContext context, AlarmSettings settings) {
    int minRange = 0;
    int maxRange = 100;
    double width = MediaQuery.of(context).size.width;
    return SettingsTile(
        //title: Text('Range High ${settings.rangeHigh}'),
        title: const Text("Volume Override"),
        trailing: SizedBox(
          width: width - 230,
          child: Row(
            children: [
              Expanded(
                  flex: 1,
                  child: InkWell(
                      child: const Icon(Icons.volume_down, color: mainColor),
                      onTap: () {
                        settings.volumeOverride =
                            max(minRange, settings.volumeOverride - 10).toInt();
                      })),
              Expanded(
                  flex: 12,
                  child: Container(
                      alignment: Alignment.center,
                      height: 20,
                      child: Slider(
                        divisions: 50,
                        value: settings.volumeOverride.toDouble(),
                        min: 0,
                        max: 100,
                        onChanged: (double value) {
                          settings.volumeOverride = value.toInt();
                        },
                      ))),
              Expanded(
                flex: 1,
                child: InkWell(
                  child: const Icon(
                    Icons.volume_up,
                    color: mainColor,
                  ),
                  onTap: () {
                    settings.volumeOverride =
                        min(maxRange, settings.volumeOverride.toDouble() + 10)
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
          1 == settings.volumeProgressionMinutes,
          2 == settings.volumeProgressionMinutes,
          3 == settings.volumeProgressionMinutes,
          4 == settings.volumeProgressionMinutes,
          5 == settings.volumeProgressionMinutes,
        ],
        onPressed: (int index) {
          var value = -1;
          switch (index) {
            case 0:
              value = 1;
              break;
            case 1:
              value = 2;
              break;
            case 2:
              value = 3;
              break;
            case 3:
              value = 4;
              break;
            case 4:
              value = 5;
              break;
          }
          if (settings.volumeProgressionMinutes == value) {
            value = -1; // disable
          }
          settings.volumeProgressionMinutes = value;
        },
        children: const [
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
          ToggleButton(
            text: "3m",
            height: _size,
            width: _size,
          ),
          ToggleButton(
            text: "4m",
            height: _size,
            width: _size,
          ),
          ToggleButton(
            text: "5m",
            height: _size,
            width: _size,
          ),
        ],
      ),
    );
  }

  SettingsTile testAlert(BuildContext context, AlarmsCN alarms) {
    double width = MediaQuery.of(context).size.width;
    return SettingsTile(
        title: const Text(""),
        trailing: SizedBox(
            width: width - 100,
            child: Center(
              child: ElevatedButton(
                onPressed: () async {
                  await alarms.test();
                },
                child: const Text("Test Alert"),
              ),
            )));
  }
}
