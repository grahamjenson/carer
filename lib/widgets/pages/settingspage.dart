import 'package:carer/widgets/settings/about_settings.dart';
import 'package:carer/widgets/settings/debug_settings.dart';
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
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
        ),
        body: SettingsList(
          sections: [
            ServicesSettingsWidget(),
            const TargetSettingsWidget(),
            const UISettingsWidget(),
            const DebugSettingsWidget(),
            const AboutSettingsWidget(),
          ],
        ),
      ),
    );
  }
}
