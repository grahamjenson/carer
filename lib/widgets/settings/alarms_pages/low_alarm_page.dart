import 'package:carer/models/settings_cn.dart';
import 'package:carer/widgets/settings/togglebutton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_settings_ui/flutter_settings_ui.dart';
import 'package:provider/provider.dart';

class LowAlarmPage extends StatelessWidget {
  const LowAlarmPage({super.key});

  static const TextStyle description = TextStyle(
    fontSize: 12,
    color: Colors.grey,
  );

  @override
  Widget build(BuildContext context) {
    return Consumer<Settings>(builder: (context, settings, child) {
      var alarmSettings = settings.alarmSettings;

// onLongPress: () async {
//                 var lowMinutes = await alertDialogOfButtons<int>(
//                     context,
//                     "Alert Low for:",
//                     ["0m", "5m", "10m", "15m", "20m", "30m"],
//                     [0, 5, 10, 15, 20, 30]);
//                 settings.lowMinutes = lowMinutes;
//               }

      return Scaffold(
        appBar: AppBar(
          title: const Text('Low Alarm'),
        ),
        body: SettingsList(sections: [
          SettingsSection(tiles: [
            SettingsTile.switchTile(
              title: const Text("Low Alarm"),
              descriptionInlineIos: true,
              description: const Text(
                "Low Alarm",
                style: description,
              ),
              initialValue: alarmSettings.lowAlarm,
              onToggle: (value) {
                alarmSettings.lowAlarm = value;
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
                  alarmSettings.lowMinutes,
                  ["0m", "5m", "10m", "15m", "20m", "30m"],
                  [0, 5, 10, 15, 20, 30],
                  (value) => alarmSettings.lowMinutes = value),
            ),
          ]),
        ]),
      );
    });
  }
}
