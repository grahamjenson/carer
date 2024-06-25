import 'package:carer/services/settings/alarm_settings.dart';
import 'package:carer/widgets/settings/togglebutton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_settings_ui/flutter_settings_ui.dart';
import 'package:signals/signals_flutter.dart';

class LowAlarmPage extends StatelessWidget {
  const LowAlarmPage({super.key});

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
      body: Watch((_) {
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
          ]),
        ]);
      }),
    );
  }
}
