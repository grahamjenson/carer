import 'package:carer/change_notifiers/settings/ui_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_settings_ui/flutter_settings_ui.dart';
import 'package:signals/signals_flutter.dart';

class UISettingsWidget extends AbstractSettingsSection {
  const UISettingsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      return SettingsSection(
        title: const Text('UI'),
        tiles: [
          SettingsTile.switchTile(
            title: const Text('Keep Screen Active'),
            initialValue: UISettings.screenActive.value,
            onToggle: (value) async {
              UISettings.screenActive.value = value;
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
              value: UISettings.uiLayoutVertical.value,
              onChanged: (value) {
                if (value == null) return;
                UISettings.uiLayoutVertical.value = value;
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
              value: UISettings.uiLayoutHorizontal.value,
              onChanged: (value) {
                if (value == null) return;
                UISettings.uiLayoutHorizontal.value = value;
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
              value: UISettings.uiTheme.value,
              onChanged: (value) {
                if (value == null) return;
                UISettings.uiTheme.value = value;
              },
            ),
          ),
        ],
      );
    });
  }
}
