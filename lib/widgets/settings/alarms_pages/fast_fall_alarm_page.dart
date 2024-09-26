import 'package:carer/services/settings/alarm_settings.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/widgets/settings/togglebutton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_settings_ui/flutter_settings_ui.dart';

class FastFallAlarmSettingsPage extends StatelessWidget {
  const FastFallAlarmSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fast Fall Alarm Settings'),
      ),
      body: AWatch(
        (context) {
          return SettingsList(
            sections: [
              SettingsSection(
                title: const Text('Fast Fall Alarm'),
                tiles: [
                  SettingsTile.switchTile(
                    title: const Text("Fast Fall Alarm"),
                    descriptionInlineIos: true,
                    description: const Text(
                      "Fast Fall Alarm",
                    ),
                    initialValue: AlarmSettings().fastDropAlarmMinutes > 0,
                    onToggle: (value) {
                      if (!value) {
                        AlarmSettings().fastDropAlarmMinutes = -1;
                      } else {
                        AlarmSettings().fastDropAlarmMinutes = 10;
                      }
                    },
                  ),
                  SettingsTile(
                    title: const Text("Minutes"),
                    descriptionInlineIos: true,
                    description: const Text(
                      "Alarm after",
                    ),
                    trailing: ToggleButton.selectOne<int>(AlarmSettings().fastDropAlarmMinutes, ["5m", "10m", "15m", "20m"], [5, 10, 15, 20],
                        (value) => AlarmSettings().fastDropAlarmMinutes = value),
                  ),
                ],
              ),
            ],
          );
        },
        debugLabel: "FastFallAlarmSettingsPage",
      ),
    );
  }
}
