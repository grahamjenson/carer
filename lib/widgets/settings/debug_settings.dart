import 'package:carer/services/ui/icons.dart';
import 'package:carer/widgets/settings/debug_pages/debug_pages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_settings_ui/flutter_settings_ui.dart';

class DebugSettingsWidget extends AbstractSettingsSection {
  const DebugSettingsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsSection(
      title: const Text('Debug'),
      tiles: [
        SettingsTile.navigation(
            title: const Text("Debug"),
            leading: const Icon(CarerIcons.SETTINGS_DEBUG),
            onPressed: (context) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DebugSettingsPage()),
              );
            }),
      ],
    );
  }
}
