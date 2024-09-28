import 'package:carer/services/alarms_service.dart';
import 'package:carer/utils/logs.dart';
import 'package:carer/widgets/settings/alarm_alerts_settings.dart';
import 'package:carer/widgets/settings/alarms_settings.dart';
import 'package:carer/widgets/settings/debug_settings.dart';
import 'package:carer/widgets/settings/device_settings.dart';
import 'package:carer/widgets/settings/services_settings.dart';
import 'package:carer/widgets/settings/t1d_settings.dart';
import 'package:carer/widgets/settings/ui_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_settings_ui/flutter_settings_ui.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvoked: (bool didPop) {
        if (didPop) {
          alog("Stop Test Alarm because POP");
          AlarmsService().stopTestAlarm();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
        ),
        body: SettingsList(
          sections: [
            ServicesSettingsWidget(),
            const T1DSettingsWidget(),
            const UISettingsWidget(),
            const AlarmsSettingsWidget(),
            const AlarmsAlertSettingsWidget(),
            const DeviceSettingsWidget(),
            const DebugSettingsWidget(),
          ],
        ),
      ),
    );
  }
}
