import 'package:carer/services/ui/icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_settings_ui/flutter_settings_ui.dart';
import 'package:go_router/go_router.dart';

class DebugSettingsWidget extends AbstractSettingsSection {
  const DebugSettingsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsSection(
      title: const Text('Debug'),
      tiles: [
        SettingsTile.navigation(
          title: const Text("Events"),
          descriptionInlineIos: true,
          onPressed: (context) async {
            GoRouter.of(context).go("/settings/events");
          },
        ),
        SettingsTile.navigation(
            title: const Text("Debug"),
            leading: const Icon(CarerIcons.SETTINGS_DEBUG),
            onPressed: (context) {
              GoRouter.of(context).go("/settings/debug");
            }),
      ],
    );
  }
}
