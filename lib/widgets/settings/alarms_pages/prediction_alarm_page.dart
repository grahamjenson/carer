import 'package:carer/services/settings/alarm_settings.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/widgets/settings/togglebutton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_settings_ui/flutter_settings_ui.dart';

class PredictionAlarmPage extends StatelessWidget {
  const PredictionAlarmPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Low Alarm'),
      ),
      body: AWatch(
        (_) {
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
                    trailing: ToggleButton.selectOne<int>(AlarmSettings().lowPredictionMinutes, ["5m", "10m", "15m", "20m", "30m"],
                        [5, 10, 15, 20, 30], (value) => AlarmSettings().lowPredictionMinutes = value),
                  ),
                ],
              ),
            ],
          );
        },
        debugLabel: "PredictionAlarmPage",
      ),
    );
  }
}
