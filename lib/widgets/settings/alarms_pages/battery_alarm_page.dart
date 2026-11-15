import 'package:carer/services/settings/alarm_settings.dart';
import 'package:carer/utils/futures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_settings_ui/flutter_settings_ui.dart';

class BatteryAlarmSettingsPage extends StatelessWidget {
  const BatteryAlarmSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Battery Alarm Settings'),
      ),
      body: AWatch(
        (context) {
          return SettingsList(
            sections: [
              SettingsSection(
                title: const Text('T1D Battery Alarm'),
                tiles: [
                  SettingsTile.switchTile(
                    title: const Text("Battery Alarm"),
                    descriptionInlineIos: true,
                    description: const Text(
                      "Alarms when T1D phones Battery < 10%",
                    ),
                    initialValue: AlarmSettings().t1dBatteryAlarm,
                    onToggle: (value) {
                      AlarmSettings().t1dBatteryAlarm = value;
                    },
                  ),
                  SettingsTile.switchTile(
                    title: const Text("Carer Battery Alarm"),
                    descriptionInlineIos: true,
                    description: const Text(
                      "Alarms when THIS devices Battery < 10%",
                    ),
                    initialValue: AlarmSettings().carerBatteryAlarm,
                    onToggle: (value) {
                      AlarmSettings().carerBatteryAlarm = value;
                    },
                  ),
                ],
              ),
            ],
          );
        },
        debugLabel: "BatteryAlarmSettingsPage",
      ),
    );
  }
}
