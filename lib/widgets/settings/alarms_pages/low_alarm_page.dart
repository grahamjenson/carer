import 'package:carer/services/settings/alarm_settings.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/widgets/settings/t1d_settings.dart';
import 'package:carer/widgets/settings/togglebutton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_settings_ui/flutter_settings_ui.dart';

class LowAlarmSettingsPage extends StatelessWidget {
  const LowAlarmSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Low Alarm Settings'),
      ),
      body: AWatch(
        (context) {
          return SettingsList(
            sections: [
              SettingsSection(
                title: const Text('Low Alarm'),
                tiles: [
                  SettingsTile.switchTile(
                    title: const Text("Low Alarm"),
                    descriptionInlineIos: true,
                    description: const Text(
                      "Low Alarm",
                    ),
                    initialValue: AlarmSettings().lowAlarm,
                    onToggle: (value) {
                      AlarmSettings().lowAlarm = value;
                    },
                  ),
                ],
              ),
              SettingsSection(
                title: const Text('Predicted Low Alarm'),
                tiles: [
                  SettingsTile.switchTile(
                    title: const Text("Predicted Low Alarm"),
                    descriptionInlineIos: true,
                    description: const Text(
                      "Low Alarm",
                    ),
                    initialValue: AlarmSettings().lowPredictionAlarm,
                    onToggle: (value) {
                      AlarmSettings().lowPredictionAlarm = value;
                    },
                  ),
                  SettingsTile(
                    title: const Text("Minutes"),
                    descriptionInlineIos: true,
                    description: const Text(
                      "Alarm after",
                    ),
                    trailing: ToggleButton.selectOne<int>(AlarmSettings().lowPredictionMinutes, ["5m", "10m", "15m", "20m"], [5, 10, 15, 20],
                        (value) => AlarmSettings().lowPredictionMinutes = value),
                  ),
                ],
              ),
              TargetSettingsWidget(
                targets: const {TargetSettingsWidgetTargets.target},
              ),
            ],
          );
        },
        debugLabel: "LowAlarmSettingsPage",
      ),
    );
  }
}
