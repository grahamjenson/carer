import 'package:carer/models/details/alarms/alarms.dart';
import 'package:carer/services/settings/alarm_alert_settings.dart';
import 'package:carer/services/settings/alarm_settings.dart';
import 'package:carer/services/settings/target_settings.dart';
import 'package:carer/services/themes_service.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/widgets/settings/alarms_pages/battery_alarm_page.dart';
import 'package:carer/widgets/settings/alarms_pages/fast_fall_alarm_page.dart';
import 'package:carer/widgets/settings/alarms_pages/fast_rise_alarm_page.dart';
import 'package:carer/widgets/settings/alarms_pages/high_alarm_page.dart';
import 'package:carer/widgets/settings/alarms_pages/low_alarm_page.dart';
import 'package:carer/widgets/settings/alarms_pages/no_data_alarm_page.dart';
import 'package:carer/widgets/settings/alarms_pages/urgent_high_alarm_page.dart';
import 'package:carer/widgets/settings/alarms_pages/urgent_low_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_settings_ui/flutter_settings_ui.dart';

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
          alarmNavigationTile(context, AlarmType.urgentLow, const UrgentAlarmLowSettingsPage()),
          alarmNavigationTile(context, AlarmType.low, const LowAlarmSettingsPage()),
          alarmNavigationTile(context, AlarmType.high, const HighAlarmSettingsPage()),
          alarmNavigationTile(context, AlarmType.urgentHigh, const UrgentAlarmHighSettingsPage()),
          alarmNavigationTile(context, AlarmType.fastRise, const FastRiseAlarmSettingsPage()),
          alarmNavigationTile(context, AlarmType.fastDrop, const FastFallAlarmSettingsPage()),
          alarmNavigationTile(context, AlarmType.noData, const NoDataAlarmSettingsPage()),
          alarmNavigationTile(context, AlarmType.lowBattery, const BatteryAlarmSettingsPage()),
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

  SettingsTile alarmNavigationTile(BuildContext context, AlarmType alarmType, Widget page) {
    Color? iconColor;
    if (alarmType.trigger()) {
      iconColor = primaryColor(context);
    }
    return SettingsTile.navigation(
      title: Text(alarmType.title),
      leading: Icon(alarmType.icon, color: iconColor),
      description: Text(alarmType.description),
      descriptionInlineIos: true,
      onPressed: (context) => Navigator.push(context, MaterialPageRoute(builder: (context) => page)),
    );
  }
}
