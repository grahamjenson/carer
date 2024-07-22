import 'package:carer/services/settings/alarm_settings.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/widgets/settings/togglebutton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_settings_ui/flutter_settings_ui.dart';

class PredictionAlarmPage extends StatelessWidget {
  const PredictionAlarmPage({super.key});

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
        return SettingsList(
          sections: [
            SettingsSection(
              title: const Text('Predicted Low Alarm'),
              tiles: [
                SettingsTile.switchTile(
                  title: const Text("Predicted Low Alarm"),
                  descriptionInlineIos: true,
                  description: const Text(
                    "Low Alarm",
                    style: description,
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
                    style: description,
                  ),
                  trailing: ToggleButton.selectOne<int>(AlarmSettings().lowPredictionMinutes, ["0m", "5m", "10m", "15m", "20m", "30m"],
                      [0, 5, 10, 15, 20, 30], (value) => AlarmSettings().lowPredictionMinutes = value),
                ),
              ],
            ),
          ],
        );
      }),
    );
  }
}
