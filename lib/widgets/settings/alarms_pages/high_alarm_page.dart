import 'package:carer/services/settings/alarm_settings.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/widgets/settings/t1d_settings.dart';
import 'package:carer/widgets/settings/togglebutton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_settings_ui/flutter_settings_ui.dart';

class HighAlarmSettingsPage extends StatelessWidget {
  const HighAlarmSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('High Alarm Settings'),
      ),
      body: AWatch(
        (context) {
          return SettingsList(
            sections: [
              SettingsSection(
                title: const Text('High Alarm'),
                tiles: [
                  SettingsTile.switchTile(
                    title: const Text("High Alarm"),
                    descriptionInlineIos: true,
                    description: const Text(
                      "High Alarm",
                    ),
                    initialValue: AlarmSettings().highAlarm,
                    onToggle: (value) {
                      AlarmSettings().highAlarm = value;
                    },
                  ),
                  SettingsTile(
                    title: const Text("Minutes"),
                    descriptionInlineIos: true,
                    description: const Text(
                      "Alarm after",
                    ),
                    trailing: ToggleButton.selectOne<int>(AlarmSettings().highMinutes, ["0m", "10m", "20m", "40m", "60m"], [0, 10, 20, 40, 60],
                        (value) => AlarmSettings().highMinutes = value),
                  ),
                ],
              ),
              SettingsSection(title: const Text('Predictive'), tiles: [
                smartSnooze(),
              ]),
              TargetSettingsWidget(
                targets: const {TargetSettingsWidgetTargets.target},
              ),
            ],
          );
        },
        debugLabel: "HighAlarmSettingsPage",
      ),
    );
  }

  SettingsTile smartSnooze() {
    return SettingsTile.switchTile(
      title: const Text("Smart Snooze"),
      descriptionInlineIos: true,
      description: const Text(
        "Snooze if in range in 10 minutes",
      ),
      initialValue: AlarmSettings().smartSnoozeHigh,
      onToggle: (bool value) {
        AlarmSettings().smartSnoozeHigh = value;
      },
    );
  }
}
