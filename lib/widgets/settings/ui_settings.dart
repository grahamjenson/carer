import 'package:carer/services/settings/ui_settings.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/widgets/settings/togglebutton.dart';
import 'package:carer/widgets/settings/ui_pages/theme_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_settings_ui/flutter_settings_ui.dart';

class UISettingsWidget extends AbstractSettingsSection {
  const UISettingsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    double size = 50;
    return AWatch(
      (context) {
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
            SettingsTile.navigation(
              title: const Text('Themes'),
              leading: const Icon(Icons.palette),
              trailing: ToggleButtons(
                constraints: BoxConstraints(maxHeight: size, maxWidth: size),
                renderBorder: true,
                borderRadius: BorderRadius.circular(10),
                borderWidth: 0,
                isSelected: [
                  true,
                  UISettings().alarmUIThemeLayout.enabled,
                  UISettings().nightUIThemeLayout.enabled,
                ],
                onPressed: (int index) async {
                  switch (index) {
                    case 0:
                      UISettings().mainUIThemeLayout.enabled = !UISettings().mainUIThemeLayout.enabled;
                      break;
                    case 1:
                      UISettings().alarmUIThemeLayout.enabled = !UISettings().alarmUIThemeLayout.enabled;
                      break;
                    case 2:
                      UISettings().nightUIThemeLayout.enabled = !UISettings().nightUIThemeLayout.enabled;
                      break;
                  }
                },
                children: [
                  ToggleButton(
                    text: "Main Layout\n${UISettings().mainUIThemeLayout.theme.viewName}",
                    height: size,
                    width: size,
                  ),
                  ToggleButton(
                    text: "Alarm Layout\n${UISettings().alarmUIThemeLayout.theme.viewName}",
                    height: size,
                    width: size,
                  ),
                  ToggleButton(
                    text: "Night Layout\n${UISettings().nightUIThemeLayout.theme.viewName}",
                    height: size,
                    width: size,
                  ),
                ],
              ),
              onPressed: (BuildContext context) {
                Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ThemePage()));
              },
            ),
          ],
        );
      },
      debugLabel: "UISettingsWidget",
    );
  }
}
