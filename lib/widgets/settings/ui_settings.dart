import 'package:carer/models/settings/ui_settings.dart';
import 'package:carer/models/settings_cn.dart';
import 'package:flutter/material.dart';
import 'package:flutter_settings_ui/flutter_settings_ui.dart';
import 'package:provider/provider.dart';

class UISettingsWidget extends AbstractSettingsSection {
  const UISettingsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<Settings>(builder: (context, settings, child) {
      return SettingsSection(
        title: const Text('UI'),
        tiles: [
          SettingsTile.switchTile(
            title: const Text('Keep Screen Active'),
            initialValue: settings.screenActive,
            onToggle: (value) async {
              settings.screenActive = value;
            },
          ),
          SettingsTile(
            title: const Text("Vertical Layout"),
            trailing: DropdownButton(
              alignment: Alignment.topLeft,
              items: UILayout.values
                  .map((e) => DropdownMenuItem(
                        value: e,
                        child: SizedBox(width: 130, child: Text(e.viewName)),
                      ))
                  .toList(),
              value: settings.uiSettings.uiLayoutVertical,
              onChanged: (value) {
                if (value == null) return;
                settings.uiSettings.uiLayoutVertical = value;
              },
            ),
          ),
          SettingsTile(
            title: const Text("Horizontal Layout"),
            trailing: DropdownButton(
              items: UILayout.values
                  .map((e) => DropdownMenuItem(
                        value: e,
                        child: SizedBox(width: 130, child: Text(e.viewName)),
                      ))
                  .toList(),
              value: settings.uiSettings.uiLayoutHorizontal,
              onChanged: (value) {
                if (value == null) return;
                settings.uiSettings.uiLayoutHorizontal = value;
              },
            ),
          ),
          SettingsTile(
            title: const Text("Theme"),
            trailing: DropdownButton(
              items: UITheme.values
                  .map((e) => DropdownMenuItem(
                        value: e,
                        child: SizedBox(width: 130, child: Text(e.viewName)),
                      ))
                  .toList(),
              value: settings.uiSettings.uiTheme,
              onChanged: (value) {
                if (value == null) return;
                settings.uiSettings.uiTheme = value;
              },
            ),
          ),
        ],
      );
    });
  }
}
