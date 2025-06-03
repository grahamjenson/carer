import 'dart:io';
import 'dart:math';

import 'package:carer/services/settings/alarm_alert_settings.dart';
import 'package:carer/services/settings/alarm_settings.dart';
import 'package:carer/services/themes_service.dart';
import 'package:carer/services/ui/icons.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/widgets/common/dialogs.dart';
import 'package:carer/widgets/settings/togglebutton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_settings_ui/flutter_settings_ui.dart';
import 'package:go_router/go_router.dart';

class AlarmsAlertSettingsWidget extends AbstractSettingsSection with ThemeMixin {
  const AlarmsAlertSettingsWidget({super.key});
  static const double _size = 50;

  @override
  Widget build(BuildContext context) {
    return AWatch(
      (context) {
        double width = min(820, MediaQuery.of(context).size.width);

        if (AlarmSettings().disableAlarms) {
          return const SizedBox.shrink();
        }
        List<SettingsTile> tiles = [
          enableFlashOnAlarm(),
          enableNotifications(),
          brightnessAdjust(),
          enableAudioAlarms(context),
          volumeOverride(context),
          volumeSettings(context, width),
          progressiveVolume(context),
          alarmFileSelect(),
          testAlert(context, width),
        ].whereType<SettingsTile>().toList();

        return SettingsSection(
          title: const Text('Alarm Alerts'),
          tiles: tiles,
        );
      },
      debugLabel: "AlarmsAlertSettingsWidget",
    );
  }

  SettingsTile? brightnessAdjust() {
    if (!Platform.isIOS && !Platform.isAndroid) {
      return null;
    }
    return SettingsTile.switchTile(
      title: const Text("Brightness Adjust"),
      descriptionInlineIos: true,
      description: const Text(
        "Up screen brightness with alarms at night",
      ),
      initialValue: AlarmAlertSettings().brightnessAdjustAtNight,
      onToggle: (bool value) {
        AlarmAlertSettings().brightnessAdjustAtNight = value;
      },
    );
  }

  SettingsTile enableFlashOnAlarm() {
    return SettingsTile.switchTile(
      title: const Text("Flash on Alarm"),
      descriptionInlineIos: true,
      description: const Flexible(
        child: Text(
          "Flashs the screen white when an alarming",
          softWrap: true,
        ),
      ),
      initialValue: AlarmAlertSettings().enableFlashOnAlarm,
      onToggle: (bool value) {
        AlarmAlertSettings().enableFlashOnAlarm = value;
      },
    );
  }

  SettingsTile enableNotifications() {
    return SettingsTile.switchTile(
      title: const Text("Notifications"),
      descriptionInlineIos: true,
      description: const Flexible(
        child: Text(
          "Notifications every 15 minutes if alarming (DANGER unreliable)",
        ),
      ),
      initialValue: AlarmAlertSettings().enableNotifications,
      onToggle: (bool value) {
        AlarmAlertSettings().enableNotifications = value;
      },
    );
  }

  SettingsTile enableAudioAlarms(BuildContext context) {
    return SettingsTile.switchTile(
      title: const Text("Audio Alarms"),
      descriptionInlineIos: true,
      description: const Flexible(
          child: Text(
        "Play audio alert when an alarming",
      )),
      initialValue: AlarmAlertSettings().enableAudioAlarm,
      onToggle: (bool enable) async {
        if (enable) {
          AlarmAlertSettings().enableAudioAlarm = enable;
          return;
        }
        // show the dialog
        bool? areYouSure = await Dialogs.areYouSureDialog(context, "Disable Audio Alerts", "Disable Audio Alerts (not recommended)?", "Disable");

        if (areYouSure == true) {
          AlarmAlertSettings().enableAudioAlarm = false;
        }
      },
    );
  }

  SettingsTile? volumeOverride(BuildContext context) {
    if (!AlarmAlertSettings().enableAudioAlarm) {
      return null;
    }
    return SettingsTile.switchTile(
      title: const Text("Volume Override"),
      initialValue: AlarmAlertSettings().volumeOveride,
      onToggle: (bool value) {
        AlarmAlertSettings().volumeOveride = value;
      },
    );
  }

  SettingsTile? volumeSettings(BuildContext context, double width) {
    if (!AlarmAlertSettings().enableAudioAlarm) {
      return null;
    }

    int minRange = 0;
    int maxRange = 100;

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
                      child: const Icon(CarerIcons.SETTINGS_VOLUME_DOWN),
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
                  child: const Icon(CarerIcons.SETTINGS_VOLUME_UP),
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

  SettingsTile? progressiveVolume(BuildContext context) {
    if (!AlarmAlertSettings().enableAudioAlarm) {
      return null;
    }

    return SettingsTile(
      title: const Text("Volume Progression"),
      trailing: ToggleButtons(
        constraints: const BoxConstraints(maxHeight: 40, maxWidth: 40),
        renderBorder: true,
        borderRadius: BorderRadius.circular(10),
        borderWidth: 4,
        isSelected: [
          30 == AlarmAlertSettings().volumeProgressionSeconds,
          60 == AlarmAlertSettings().volumeProgressionSeconds,
          120 == AlarmAlertSettings().volumeProgressionSeconds,
        ],
        onPressed: (int index) {
          var value = -1;
          switch (index) {
            case 0:
              value = 30;
              break;
            case 1:
              value = 60;
              break;
            case 2:
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

  SettingsTile? alarmFileSelect() {
    if (!AlarmAlertSettings().enableAudioAlarm) {
      return null;
    }
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
            width: _size * 1.2,
          ),
          ToggleButton(
            text: "Lets Go",
            height: _size,
            width: _size,
          ),
          ToggleButton(
            text: "Hybridas",
            height: _size,
            width: _size,
          ),
        ],
      ),
    );
  }

  SettingsTile testAlert(BuildContext context, double width) {
    var bStyle = ButtonStyle(
      backgroundColor: WidgetStateProperty.all(errorColor(context)),
    );
    var tStyle = TextStyle(color: onErrorColor(context));
    var button = ElevatedButton(
        onPressed: () async {
          AlarmAlertSettings().testAlarm = true;
          GoRouter.of(context).go("/display");
        },
        style: bStyle,
        child: Text("Test Alarm", style: tStyle));

    if (AlarmAlertSettings().testAlarm) {
      button = ElevatedButton(
        onPressed: () async {
          AlarmAlertSettings().testAlarm = false;
        },
        style: bStyle,
        child: Text("Stop Test Alarm", style: tStyle),
      );
    }

    return SettingsTile(title: const Text(""), trailing: SizedBox(width: width - 100, child: Center(child: button)));
  }
}
