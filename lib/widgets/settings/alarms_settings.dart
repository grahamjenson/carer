import 'package:carer/models/settings/alarm_settings.dart';
import 'package:carer/models/settings_cn.dart';
import 'package:carer/widgets/settings/togglebutton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_settings_ui/flutter_settings_ui.dart';
import 'package:provider/provider.dart';
import 'package:unicons/unicons.dart';

class AlarmsSettingsWidget extends AbstractSettingsSection {
  const AlarmsSettingsWidget({super.key});

  static const TextStyle description = TextStyle(
    fontSize: 12,
    color: Colors.grey,
  );

  @override
  Widget build(BuildContext context) {
    return Consumer<Settings>(builder: (context, settings, child) {
      var alarmSettings = settings.alarmSettings;
      return SettingsSection(
        title: const Text('Alarms\n(Long Press for info and settings)'),
        tiles: [
          targetSettings(context, alarmSettings),
          diffSettings(context, alarmSettings),
          noDataAlarmSettings(alarmSettings),
          predictionAlarms(alarmSettings),
          predictiveSnooze(alarmSettings),
        ],
      );
    });
  }

  SettingsTile targetSettings(BuildContext context, AlarmSettings settings) {
    return SettingsTile(
      title: const Text("Range"),
      descriptionInlineIos: true,
      description: const Text(
        "Out of target/urgent range",
        style: description,
      ),
      trailing: ToggleButtons(
        constraints: const BoxConstraints(maxHeight: 40, maxWidth: 40),
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
          ToggleButton(text: "Urgent Low", icon: UniconsLine.angle_double_down),
          ToggleButton(text: "Low", icon: UniconsLine.angle_down),
          ToggleButton(text: "High", icon: UniconsLine.angle_up),
          ToggleButton(text: "Urgent High", icon: UniconsLine.angle_double_up),
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
        constraints: const BoxConstraints(maxHeight: 40, maxWidth: 40),
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
              text: "Fast Drop ${settings.fastDropAlarmMinutes}m",
              icon: UniconsLine.arrow_down_left,
              onLongPress: () async {
                var x = await alertDialogOfButtons<int>(context,
                    "Alert Dropping for:", ["15m", "20m", "30m"], [15, 20, 30]);
                settings.fastDropAlarmMinutes = x;
              }),
          const ToggleButton(
              text: "Fast Rise", icon: UniconsLine.arrow_up_left),
        ],
      ),
    );
  }

  SettingsTile noDataAlarmSettings(AlarmSettings settings) {
    return SettingsTile(
      title: const Text("No Data"),
      trailing: ToggleButtons(
        constraints: const BoxConstraints(maxHeight: 40, maxWidth: 40),
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
          ToggleButton(text: "10m", icon: UniconsLine.clock_two),
          ToggleButton(text: "20m", icon: UniconsLine.clock_five),
          ToggleButton(text: "30m", icon: UniconsLine.clock_eight),
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
        constraints: const BoxConstraints(maxHeight: 40, maxWidth: 40),
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
          ToggleButton(text: "Simple", icon: UniconsLine.temperature_empty),
          ToggleButton(text: "Profile", icon: UniconsLine.temperature_half),
          // ToggleButton(text: "Smart Model 1", icon: UniconsLine.temperature),
          // ToggleButton(text: "Smart Model 2", icon: UniconsLine.temperature_plus),
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
        constraints: const BoxConstraints(maxHeight: 40, maxWidth: 40),
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
            icon: UniconsLine.bed,
          ),
          ToggleButton(
            text: "Profile",
            icon: UniconsLine.bed,
          ),
          // ToggleButton(text: "Smart Model 2", icon: UniconsLine.temperature_plus),
        ],
      ),
    );
  }
}
