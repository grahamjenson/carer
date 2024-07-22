import 'package:carer/services/settings/alarm_settings.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/widgets/settings/togglebutton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_settings_ui/flutter_settings_ui.dart';

class DiffAlarmPage extends StatelessWidget {
  const DiffAlarmPage({super.key});

  static const TextStyle description = TextStyle(
    fontSize: 12,
    color: Colors.grey,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fast Drop Alarm'),
      ),
      body: AWatch((_) {
        return SettingsList(
          sections: [
            SettingsSection(
              title: const Text('Fast Drop Alarm'),
              tiles: [
                SettingsTile.switchTile(
                  title: const Text("Fast Drop Alarm"),
                  descriptionInlineIos: true,
                  description: const Text(
                    "Fast Drop Alarm",
                    style: description,
                  ),
                  initialValue: AlarmSettings().fastDropAlarm,
                  onToggle: (value) {
                    AlarmSettings().fastDropAlarm = value;
                  },
                ),
                SettingsTile(
                  title: const Text("Minutes"),
                  descriptionInlineIos: true,
                  description: const Text(
                    "Alarm after",
                    style: description,
                  ),
                  trailing: ToggleButton.selectOne<int>(AlarmSettings().fastDropAlarmMinutes, ["5m", "10m", "15m", "20m", "30m"], [5, 10, 15, 20, 30],
                      (value) => AlarmSettings().fastDropAlarmMinutes = value),
                ),
              ],
            ),
            SettingsSection(
              title: const Text('Fast Rise Alarm'),
              tiles: [
                SettingsTile.switchTile(
                  title: const Text("Fast Rise Alarm"),
                  descriptionInlineIos: true,
                  description: const Text(
                    "Fast Rise Alarm",
                    style: description,
                  ),
                  initialValue: AlarmSettings().fastRiseAlarm,
                  onToggle: (value) {
                    AlarmSettings().fastRiseAlarm = value;
                  },
                ),
                SettingsTile(
                  title: const Text("Minutes"),
                  descriptionInlineIos: true,
                  description: const Text(
                    "Alarm after",
                    style: description,
                  ),
                  trailing: ToggleButton.selectOne<int>(AlarmSettings().fastRiseAlarmMinutes, ["5m", "10m", "15m", "20m", "30m"], [5, 10, 15, 20, 30],
                      (value) => AlarmSettings().fastRiseAlarmMinutes = value),
                ),
              ],
            ),
          ],
        );
      }),
    );
  }
}
