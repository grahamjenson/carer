import 'package:carer/services/settings/alarm_settings.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/widgets/settings/t1d_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_settings_ui/flutter_settings_ui.dart';

class UrgentAlarmHighSettingsPage extends StatelessWidget {
  const UrgentAlarmHighSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Urgent High Alarm Settings'),
      ),
      body: AWatch(
        (context) {
          return SettingsList(
            sections: [
              SettingsSection(
                title: const Text('Urgent High Alarm'),
                tiles: [
                  SettingsTile.switchTile(
                    title: const Text("Urgent High Alarm"),
                    descriptionInlineIos: true,
                    description: const Text(
                      "Urgent High Alarm",
                    ),
                    initialValue: AlarmSettings().urgentHighAlarm,
                    onToggle: (value) {
                      AlarmSettings().urgentHighAlarm = value;
                    },
                  ),
                ],
              ),
              TargetSettingsWidget(
                targets: const {TargetSettingsWidgetTargets.target},
              ),
            ],
          );
        },
        debugLabel: "UrgentAlarmHighSettingsPage",
      ),
    );
  }
}
