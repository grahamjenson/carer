import 'package:carer/services/settings/ui_settings.dart';
import 'package:carer/utils/dates.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/widgets/settings/togglebutton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_settings_ui/flutter_settings_ui.dart';

class UISettingsWidget extends AbstractSettingsSection {
  const UISettingsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return AWatch((context) {
      return SettingsSection(
        title: const Text('UI'),
        tiles: [
          SettingsTile.switchTile(
            title: const Text('Keep Screen Active'),
            initialValue: UISettings().screenActive,
            onToggle: (value) async {
              UISettings().screenActive = value;
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
              value: UISettings().uiLayoutVertical,
              onChanged: (value) {
                if (value == null) return;
                UISettings().uiLayoutVertical = value;
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
              value: UISettings().uiLayoutHorizontal,
              onChanged: (value) {
                if (value == null) return;
                UISettings().uiLayoutHorizontal = value;
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
              value: UISettings().uiTheme,
              onChanged: (value) {
                if (value == null) return;
                UISettings().uiTheme = value;
              },
            ),
          ),
          SettingsTile(
            title: const Text("Night Theme"),
            trailing: DropdownButton(
              items: UITheme.values
                  .map((e) => DropdownMenuItem(
                        value: e,
                        child: SizedBox(width: 130, child: Text(e.viewName)),
                      ))
                  .toList(),
              value: UISettings().nightTheme,
              onChanged: (value) {
                if (value == null) return;
                UISettings().nightTheme = value;
              },
            ),
          ),
          SettingsTile(
            title: const Text("Day Time"),
            trailing: ToggleButtons(
              constraints: const BoxConstraints(maxHeight: 50, maxWidth: 100),
              renderBorder: true,
              borderRadius: BorderRadius.circular(10),
              borderWidth: 0,
              isSelected: [
                UISettings().isNightModeActive(),
                UISettings().isNightModeActive(),
              ],
              onPressed: (int index) async {
                switch (index) {
                  case 0:
                    TimeOfDay? value = await showTimePicker(context: context, initialTime: UISettings().nightStartTime);
                    if (value != null) {
                      UISettings().nightStartTime = value;
                    }
                    break;
                  case 1:
                    TimeOfDay? value = await showTimePicker(context: context, initialTime: UISettings().nightEndTime);
                    if (value != null) {
                      UISettings().nightEndTime = value;
                    }
                    break;
                }
              },
              children: [
                ToggleButton(
                  text: "Night Start\n${Dates.tODToString(UISettings().nightStartTime)}",
                  height: 50,
                  width: 70,
                ),
                ToggleButton(
                  text: "Night End\n${Dates.tODToString(UISettings().nightEndTime)}",
                  height: 50,
                  width: 70,
                ),
              ],
            ),
          ),
        ],
      );
    });
  }
}
