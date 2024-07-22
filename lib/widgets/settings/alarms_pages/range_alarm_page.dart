import 'package:carer/services/settings/alarm_settings.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/widgets/settings/togglebutton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_settings_ui/flutter_settings_ui.dart';

class RangeAlarmPage extends StatelessWidget {
  const RangeAlarmPage({super.key});

  static const TextStyle description = TextStyle(
    fontSize: 12,
    color: Colors.grey,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Low Alarm'),
      ),
      body: AWatch((_) {
        return SettingsList(sections: [
          SettingsSection(tiles: [
            SettingsTile.switchTile(
              title: const Text("Low Alarm"),
              descriptionInlineIos: true,
              description: const Text(
                "Low Alarm",
                style: description,
              ),
              initialValue: AlarmSettings().lowAlarm,
              onToggle: (value) {
                AlarmSettings().lowAlarm = value;
              },
            ),
            SettingsTile(
              title: const Text("Minutes"),
              descriptionInlineIos: true,
              description: const Text(
                "Alarm after",
                style: description,
              ),
              trailing: ToggleButton.selectOne<int>(AlarmSettings().lowMinutes, ["0m", "5m", "10m", "15m", "20m", "30m"], [0, 5, 10, 15, 20, 30],
                  (value) => AlarmSettings().lowMinutes = value),
            ),
            SettingsTile.switchTile(
              title: const Text("High Alarm"),
              descriptionInlineIos: true,
              description: const Text(
                "High Alarm",
                style: description,
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
                style: description,
              ),
              trailing: ToggleButton.selectOne<int>(
                  AlarmSettings().highMinutes, ["0m", "20m", "40m", "60m"], [0, 20, 40, 60], (value) => AlarmSettings().highMinutes = value),
            ),
          ]),
        ]);
      }),
    );
  }
}
