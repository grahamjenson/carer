import 'package:carer/models/alarms_cn.dart';
import 'package:carer/widgets/settings/alarms_settings.dart';
import 'package:carer/widgets/settings/debug_settings.dart';
import 'package:carer/widgets/settings/nightscout_settings.dart';
import 'package:carer/widgets/settings/t1d_settings.dart';
import 'package:carer/widgets/settings/ui_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_settings_ui/flutter_settings_ui.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AlarmsCN>(builder: (context, alarms, child) {
      return PopScope(
        onPopInvoked: (bool didPop) {
          print(didPop);
          if (didPop) {
            alarms.stopTestAlarm();
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Settings'),
          ),
          body: SettingsList(
            sections: [
              NightscoutSettingsWidget(),
              const T1DSettingsWidget(),
              const UISettingsWidget(),
              const AlarmsSettingsWidget(),
              const DebugSettingsWidget(),
            ],
          ),
        ),
      );
    });
  }
}
