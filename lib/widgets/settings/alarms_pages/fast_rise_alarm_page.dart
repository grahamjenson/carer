import 'package:carer/services/settings/alarm_settings.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/widgets/settings/t1d_settings.dart';
import 'package:carer/widgets/settings/togglebutton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_settings_ui/flutter_settings_ui.dart';

class FastRiseAlarmSettingsPage extends StatelessWidget {
  const FastRiseAlarmSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fast Rise Alarm Settings'),
      ),
      body: AWatch(
        (context) {
          return SettingsList(
            sections: [
              SettingsSection(
                title: const Text('Fast Rise Alarm'),
                tiles: [
                  SettingsTile.switchTile(
                    title: const Text("Fast Rise Alarm"),
                    descriptionInlineIos: true,
                    description: const Text(
                      "Fast Rise Alarm",
                    ),
                    initialValue: AlarmSettings().fastRiseAlarmMinutes > 0,
                    onToggle: (value) {
                      if (!value) {
                        AlarmSettings().fastRiseAlarmMinutes = -1;
                      } else {
                        AlarmSettings().fastRiseAlarmMinutes = 10;
                      }
                    },
                  ),
                  SettingsTile(
                    title: const Text("Minutes"),
                    descriptionInlineIos: true,
                    description: const Text(
                      "Alarm after",
                    ),
                    trailing: ToggleButton.selectOne<int>(AlarmSettings().fastRiseAlarmMinutes, ["5m", "10m", "15m", "20m"], [5, 10, 15, 20],
                        (value) => AlarmSettings().fastRiseAlarmMinutes = value),
                  ),
                ],
              ),
              TargetSettingsWidget(
                targets: const {TargetSettingsWidgetTargets.dropRise},
              ),
            ],
          );
        },
        debugLabel: "FastRiseAlarmSettingsPage",
      ),
    );
  }
}
