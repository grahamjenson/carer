import 'dart:math';

import 'package:carer/services/alarms_service.dart';
import 'package:carer/services/settings/alarm_alert_settings.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/widgets/colours.dart';
import 'package:carer/widgets/settings/togglebutton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_settings_ui/flutter_settings_ui.dart';

class AlarmsAlertSettingsWidget extends AbstractSettingsSection {
  const AlarmsAlertSettingsWidget({super.key});
  static const double _size = 50;

  static const TextStyle description = TextStyle(
    fontSize: 12,
    color: Colors.grey,
  );

  @override
  Widget build(BuildContext context) {
    return AWatch((context) {
      double width = min(820, MediaQuery.of(context).size.width);

      var tiles = [
        smartSnooze(),
        volumeOverride(context),
        volumeSettings(context, width),
        progressiveVolume(context),
        alarmFileSelect(),
        testAlert(context, width),
      ];

      return SettingsSection(
        title: const Text('Alarm Alert'),
        tiles: tiles,
      );
    });
  }

  SettingsTile smartSnooze() {
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

  SettingsTile volumeSettings(BuildContext context, double width) {
    int minRange = 0;
    int maxRange = 100;

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

  SettingsTile testAlert(BuildContext context, double width) {
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
