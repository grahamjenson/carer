import 'package:carer/services/settings/alarm_settings.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/widgets/settings/togglebutton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_settings_ui/flutter_settings_ui.dart';

class NoDataAlarmSettingsPage extends StatelessWidget {
  const NoDataAlarmSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('No Data Alarm Settings'),
      ),
      body: AWatch(
        (context) {
          return SettingsList(
            sections: [
              SettingsSection(
                title: const Text('No Data Alarm'),
                tiles: [
                  SettingsTile.switchTile(
                    title: const Text("No Data Alarm"),
                    descriptionInlineIos: true,
                    description: const Text(
                      "No Data Alarm",
                    ),
                    initialValue: AlarmSettings().noDataAlarmMinutes > 0,
                    onToggle: (value) {
                      if (!value) {
                        AlarmSettings().noDataAlarmMinutes = -1;
                      } else {
                        AlarmSettings().noDataAlarmMinutes = 20;
                      }
                    },
                  ),
                  SettingsTile(
                    title: const Text("Minutes"),
                    descriptionInlineIos: true,
                    description: const Text(
                      "Alarm after",
                    ),
                    trailing: ToggleButton.selectOne<int>(AlarmSettings().noDataAlarmMinutes, ["10m", "20m", "30m"], [10, 20, 30],
                        (value) => AlarmSettings().noDataAlarmMinutes = value),
                  ),
                ],
              ),
            ],
          );
        },
        debugLabel: "NoDataAlarmSettingsPage",
      ),
    );
  }
}
