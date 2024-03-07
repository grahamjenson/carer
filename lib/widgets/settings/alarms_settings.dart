import 'package:carer/models/settings_cn.dart';
import 'package:carer/widgets/settings/togglebutton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_settings_ui/flutter_settings_ui.dart';
import 'package:provider/provider.dart';
import 'package:unicons/unicons.dart';

class AlarmsSettings extends AbstractSettingsSection {
  const AlarmsSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<Settings>(builder: (context, settings, child) {
      return SettingsSection(
        title: const Text('Alarms'),
        tiles: [
          SettingsTile(
            title: const Text("Boundary Alarms"),
            trailing: ToggleButtons(
              isSelected: [
                settings.alarmSettings.urgentLowAlarm,
                settings.alarmSettings.lowAlarm,
                settings.alarmSettings.highAlarm,
                settings.alarmSettings.urgentHighAlarm,
              ],
              onPressed: (int index) {
                switch (index) {
                  case 0:
                    settings.alarmSettings.urgentLowAlarm =
                        !settings.alarmSettings.urgentLowAlarm;
                    break;
                  case 1:
                    settings.alarmSettings.lowAlarm =
                        !settings.alarmSettings.lowAlarm;
                    break;
                  case 2:
                    settings.alarmSettings.highAlarm =
                        !settings.alarmSettings.highAlarm;
                    break;
                  case 3:
                    settings.alarmSettings.urgentHighAlarm =
                        !settings.alarmSettings.urgentHighAlarm;
                    break;
                }
              },
              children: const [
                ToggleButton(
                    text: "Urgent Low", icon: UniconsLine.angle_double_down),
                ToggleButton(text: "Low", icon: UniconsLine.angle_down),
                ToggleButton(text: "High", icon: UniconsLine.angle_up),
                ToggleButton(
                    text: "Urgent High", icon: UniconsLine.angle_double_up),
              ],
            ),
          ),
          SettingsTile(
            title: const Text("Difference Alarms"),
            trailing: ToggleButtons(
              isSelected: [
                settings.alarmSettings.fastDropAlarm,
                settings.alarmSettings.fastRiseAlarm,
              ],
              onPressed: (int index) {
                switch (index) {
                  case 0:
                    settings.alarmSettings.fastDropAlarm =
                        !settings.alarmSettings.fastDropAlarm;
                    break;
                  case 1:
                    settings.alarmSettings.fastRiseAlarm =
                        !settings.alarmSettings.fastRiseAlarm;
                    break;
                }
              },
              children: const [
                ToggleButton(
                    text: "Fast Drop", icon: UniconsLine.arrow_down_left),
                ToggleButton(
                    text: "Fast Rise", icon: UniconsLine.arrow_up_left),
              ],
            ),
          ),
          SettingsTile(
            title: const Text("No Data Alarm"),
            trailing: ToggleButtons(
              isSelected: [
                10 == settings.alarmSettings.noDataAlarmMinutes,
                20 == settings.alarmSettings.noDataAlarmMinutes,
                30 == settings.alarmSettings.noDataAlarmMinutes,
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
                if (value == settings.alarmSettings.noDataAlarmMinutes) {
                  value = -1; // disable
                }
                settings.alarmSettings.noDataAlarmMinutes = value;
              },
              children: const [
                ToggleButton(text: "10m", icon: UniconsLine.clock_two),
                ToggleButton(text: "20m", icon: UniconsLine.clock_five),
                ToggleButton(text: "30m", icon: UniconsLine.clock_eight),
              ],
            ),
          ),
        ],
      );
    });
  }
}
