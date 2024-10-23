import 'package:carer/widgets/settings/stats_settings.dart';
import 'package:carer/widgets/settings/status_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_settings_ui/flutter_settings_ui.dart';

class InfoSettingsPage extends StatelessWidget {
  const InfoSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Display Settings'),
        ),
        body: const SettingsList(
          sections: [
            StatsSettingsWidget(),
            StatusSettingsWidget(),
          ],
        ),
      ),
    );
  }
}
