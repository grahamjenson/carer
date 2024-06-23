import 'package:carer/change_notifiers/settings/alarm_settings.dart';
import 'package:carer/widgets/settings/togglebutton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_settings_ui/flutter_settings_ui.dart';
import 'package:signals/signals_flutter.dart';

class HighAlarmPage extends StatelessWidget {
  const HighAlarmPage({super.key});

  static const TextStyle description = TextStyle(
    fontSize: 12,
    color: Colors.grey,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('High Alarm'),
      ),
      body: Watch((_) {
        return SettingsList(sections: [
          SettingsSection(tiles: [
            SettingsTile.switchTile(
              title: const Text("High Alarm"),
              descriptionInlineIos: true,
              description: const Text(
                "High Alarm",
                style: description,
              ),
              initialValue: AlarmSettings.highAlarm.value,
              onToggle: (value) {
                AlarmSettings.highAlarm.value = value;
              },
            ),
            SettingsTile(
              title: const Text("Minutes"),
              descriptionInlineIos: true,
              description: const Text(
                "Alarm after",
                style: description,
              ),
              trailing: ToggleButton.selectOne<int>(
                  AlarmSettings.highMinutes.value,
                  ["0m", "5m", "10m", "15m", "20m", "30m"],
                  [0, 5, 10, 15, 20, 30],
                  (value) => AlarmSettings.highMinutes.value = value),
            ),
          ]),
        ]);
      }),
    );
  }
}
