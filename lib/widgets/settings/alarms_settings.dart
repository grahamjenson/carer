import 'package:carer/models/details/alarms/alarms.dart';
import 'package:carer/services/settings/alarm_alert_settings.dart';
import 'package:carer/services/settings/alarm_settings.dart';
import 'package:carer/services/settings/target_settings.dart';
import 'package:carer/services/themes_service.dart';
import 'package:carer/utils/futures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_settings_ui/flutter_settings_ui.dart';
import 'package:go_router/go_router.dart';

class AlarmsSettingsWidget extends AbstractSettingsSection with ThemeMixin {
  const AlarmsSettingsWidget({super.key});
  static const double _size = 50;

  @override
  Widget build(BuildContext context) {
    return AWatch(
      (context) {
        if (AlarmSettings().disableAlarms) {
          return const SizedBox.shrink();
        }
        List<SettingsTile> tiles = [
          alarmNavigationTile(context, AlarmType.urgentLow, "/alarms/urgent_low_alarm"),
          alarmNavigationTile(context, AlarmType.low, "/alarms/low_alarm"),
          alarmNavigationTile(context, AlarmType.high, "/alarms/high_alarm"),
          alarmNavigationTile(context, AlarmType.urgentHigh, "/alarms/urgent_high_alarm"),
          alarmNavigationTile(context, AlarmType.fastRise, "/alarms/fast_rise_alarm"),
          alarmNavigationTile(context, AlarmType.fastDrop, "/alarms/fast_drop_alarm"),
          alarmNavigationTile(context, AlarmType.noData, "/alarms/no_data_alarm"),
          alarmNavigationTile(context, AlarmType.lowBattery, "/alarms/battery_alarm"),
        ];

        return SettingsSection(
          title: const Text('Alarms'),
          tiles: tiles,
        );
      },
      debugLabel: "AlarmsSettingsWidget",
      dependencies: AlarmSettings().allSignals() + TargetSettings().allSignals() + AlarmAlertSettings().allSignals(),
    );
  }

  SettingsTile alarmNavigationTile(BuildContext context, AlarmType alarmType, String page) {
    Color? iconColor;
    if (alarmType.trigger()) {
      iconColor = primaryColor(context);
    }
    return SettingsTile.navigation(
      title: Text(alarmType.title),
      leading: Icon(alarmType.icon, color: iconColor),
      description: Flexible(child: Text(alarmType.description)),
      descriptionInlineIos: true,
      onPressed: (context) => GoRouter.of(context).go(page),
    );
  }
}
