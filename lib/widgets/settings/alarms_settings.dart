import 'package:carer/models/settings/alarm_settings.dart';
import 'package:carer/models/settings_cn.dart';
import 'package:carer/widgets/settings/togglebutton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_settings_ui/flutter_settings_ui.dart';
import 'package:provider/provider.dart';
import 'package:unicons/unicons.dart';

class AlarmsSettingsWidget extends AbstractSettingsSection {
  const AlarmsSettingsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<Settings>(builder: (context, settings, child) {
      var alarmSettings = settings.alarmSettings;
      return SettingsSection(
        title: const Text('Alarms'),
        tiles: [
          bounarySettings(alarmSettings),
          diffSettings(alarmSettings),
          noDataAlarmSettings(alarmSettings),
          predictionAlarms(alarmSettings),
          predictiveSnooze(alarmSettings),
        ],
      );
    });
  }

  SettingsTile bounarySettings(AlarmSettings settings) {
    return SettingsTile(
      title: const Text("Boundary Alarms"),
      descriptionInlineIos: false,
      description:
          const Text("Alarm when boundary is crossed (for number of readings)"),
      trailing: ToggleButtons(
        isSelected: [
          settings.urgentLowAlarm,
          settings.lowAlarm,
          settings.highAlarm,
          settings.urgentHighAlarm,
        ],
        onPressed: (int index) {
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

  SettingsTile diffSettings(AlarmSettings settings) {
    return SettingsTile(
      title: const Text("Difference Alarms"),
      descriptionInlineIos: false,
      description:
          const Text("Alarm when rising or dropping (for number of readings)"),
      trailing: ToggleButtons(
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
        children: const [
          ToggleButton(text: "Fast Drop", icon: UniconsLine.arrow_down_left),
          ToggleButton(text: "Fast Rise", icon: UniconsLine.arrow_up_left),
        ],
      ),
    );
  }

  SettingsTile noDataAlarmSettings(AlarmSettings settings) {
    return SettingsTile(
      title: const Text("No Data Alarm"),
      descriptionInlineIos: false,
      description:
          const Text("Alarm when no readings are received for a period"),
      trailing: ToggleButtons(
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
      title: const Text("Prediction Alarms"),
      descriptionInlineIos: false,
      description: const Text(
          "Alarm when predicted to go out of bounds (in a timeframe)"),
      trailing: ToggleButtons(
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
      descriptionInlineIos: false,
      description: const Text(
          "Snooze Alarm if predicted to be in bounds (in a timeframe)"),
      trailing: ToggleButtons(
        isSelected: [
          settings.predictionAlgorithm == PredictionAlgorithm.simple,
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
            icon: UniconsLine.bed,
            superscriptIcon: UniconsLine.temperature_empty,
          ),
          // ToggleButton(text: "Smart Model 1", icon: UniconsLine.temperature),
          // ToggleButton(text: "Smart Model 2", icon: UniconsLine.temperature_plus),
        ],
      ),
    );
  }
}
