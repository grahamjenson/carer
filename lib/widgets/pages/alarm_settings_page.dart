import 'package:carer/services/settings/alarm_settings.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/widgets/common/dialogs.dart';
import 'package:carer/widgets/settings/alarm_alerts_settings.dart';
import 'package:carer/widgets/settings/alarms_settings.dart';
import 'package:carer/widgets/settings/events_page.dart';
import 'package:carer/widgets/settings/snooze_alarms_settings.dart';
import 'package:carer/widgets/settings/t1d_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_settings_ui/flutter_settings_ui.dart';

class AlarmsSettingsPage extends StatelessWidget {
  const AlarmsSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AWatch(
      (context) {
        var sections = [
          SettingsSection(tiles: [
            disableAlarms(context),
          ]),
          const TargetSettingsWidget(),
          const AlarmsSettingsWidget(),
          const AlarmsAlertSettingsWidget(),
          const SnoozeAlarmsSettings(),
          getEventsPage(),
        ];

        if (AlarmSettings().disableAlarms) {
          sections = [
            SettingsSection(tiles: [
              disableAlarms(context),
            ]),
          ];
        }
        return Scaffold(
          appBar: AppBar(
            title: const Text('Alarm Settings'),
          ),
          body: SettingsList(
            sections: sections,
          ),
        );
      },
      debugLabel: "AlarmsSettingsPage",
      dependencies: [AlarmSettings().disableAlarmsSignal],
    );
  }

  SettingsTile disableAlarms(BuildContext context) {
    return SettingsTile.switchTile(
      title: const Text("Disable Alarms"),
      descriptionInlineIos: true,
      description: const Text(
        "Turn off all alarms",
      ),
      initialValue: AlarmSettings().disableAlarms,
      onToggle: (bool disable) async {
        if (!disable) {
          AlarmSettings().disableAlarms = false;
          return;
        }
        // show the dialog
        bool? areYouSure = await Dialogs.areYouSureDialog(context, "Disable Alarms", "Disable all alarms (not recommended)?", "Disable");
        if (areYouSure == true) {
          AlarmSettings().disableAlarms = true;
        }
      },
    );
  }

  SettingsSection getEventsPage() {
    return SettingsSection(
      title: const Text('Logs'),
      tiles: [
        SettingsTile.navigation(
          title: const Text("Events"),
          descriptionInlineIos: true,
          onPressed: (context) async {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const EventsPage()),
            );
          },
        )
      ],
    );
  }
}
