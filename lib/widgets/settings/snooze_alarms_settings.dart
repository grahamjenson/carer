import 'package:carer/services/settings/alarm_alert_settings.dart';
import 'package:carer/services/settings/alarm_settings.dart';
import 'package:carer/services/themes_service.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/widgets/settings/shared/text_wrap.dart';
import 'package:flutter/material.dart';
import 'package:flutter_settings_ui/flutter_settings_ui.dart';

class SnoozeAlarmsSettings extends AbstractSettingsSection with ThemeMixin {
  const SnoozeAlarmsSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return AWatch(
      (context) {
        if (AlarmSettings().disableAlarms) {
          return const SizedBox.shrink();
        }
        List<SettingsTile> tiles = [
          wakeUpInRange(),
          wakeUpWhenUrgent(),
        ].whereType<SettingsTile>().toList();

        return SettingsSection(
          title: const Text('Snooze Settings'),
          tiles: tiles,
        );
      },
      debugLabel: "SnoozeAlarmsSettings",
    );
  }

  SettingsTile wakeUpInRange() {
    return SettingsTile.switchTile(
      title: const Text("Stop Snoozing When In Range"),
      descriptionInlineIos: true,
      description: const TextWrap(
        child: Text(
          "Stop Snoozing after 20 minutes in range",
        ),
      ),
      initialValue: AlarmAlertSettings().enableWakeUpInRange,
      onToggle: (bool value) {
        AlarmAlertSettings().enableWakeUpInRange = value;
      },
    );
  }

  SettingsTile wakeUpWhenUrgent() {
    return SettingsTile.switchTile(
      title: const Text("Stop Snoozing With Urgent Alarm"),
      descriptionInlineIos: true,
      description: const TextWrap(
        child: Text(
          "Stop Snoozing for Urgent Alarms\nUrgent High, Urgent Low and No Data\nSnoozing an Urgent Alarm will snooze",
        ),
      ),
      initialValue: AlarmAlertSettings().enableWakeUpWhenUrgent,
      onToggle: (bool value) {
        AlarmAlertSettings().enableWakeUpWhenUrgent = value;
      },
    );
  }
}
