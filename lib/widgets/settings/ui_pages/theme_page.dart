import 'package:carer/services/settings/ui_settings.dart';
import 'package:carer/utils/dates.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/widgets/settings/togglebutton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_settings_ui/flutter_settings_ui.dart';

class ThemePage extends StatelessWidget {
  const ThemePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Themes and Layout'),
      ),
      body: AWatch(
        (_) {
          return SettingsList(
            sections: [
              SettingsSection(
                title: const Text('Main Layout'),
                tiles: getThemeLayoutSettings(UISettings().mainUIThemeLayout),
              ),
              SettingsSection(
                title: const Text('Alarm Layout'),
                tiles: getThemeLayoutSettings(UISettings().alarmUIThemeLayout),
              ),
              SettingsSection(
                title: const Text('Night Layout'),
                tiles: getThemeLayoutSettings(UISettings().nightUIThemeLayout) + [timeSettingTile(context)],
              ),
            ],
          );
        },
        debugLabel: "ThemePage",
      ),
    );
  }

  List<SettingsTile> getThemeLayoutSettings(UIThemeLayout themeLayout) {
    List<SettingsTile> tiles = [];
    bool enabled = true;
    if (themeLayout != UISettings().mainUIThemeLayout) {
      enabled = themeLayout.enabled;
      tiles.add(SettingsTile.switchTile(
        title: const Text('Enabled'),
        initialValue: themeLayout.enabled,
        onToggle: (value) {
          themeLayout.enabled = value;
        },
      ));
    }

    tiles.add(
      SettingsTile(
        title: const Text("Vertical Layout"),
        enabled: enabled,
        trailing: DropdownButton(
          alignment: Alignment.topLeft,
          items: UILayout.values
              .map((e) => DropdownMenuItem(
                    value: e,
                    child: SizedBox(width: 130, child: Text(e.viewName)),
                  ))
              .toList(),
          value: themeLayout.verticalLayout,
          onChanged: (value) {
            if (value == null) return;
            themeLayout.verticalLayout = value;
          },
        ),
      ),
    );

    tiles.add(
      SettingsTile(
        title: const Text("Horizontal Layout"),
        enabled: enabled,
        trailing: DropdownButton(
          items: UILayout.values
              .map((e) => DropdownMenuItem(
                    value: e,
                    child: SizedBox(width: 130, child: Text(e.viewName)),
                  ))
              .toList(),
          value: themeLayout.horizonalLayout,
          onChanged: (value) {
            if (value == null) return;
            themeLayout.horizonalLayout = value;
          },
        ),
      ),
    );

    tiles.add(SettingsTile(
      title: const Text("Theme"),
      enabled: enabled,
      trailing: DropdownButton(
        items: UITheme.values
            .map((e) => DropdownMenuItem(
                  value: e,
                  child: SizedBox(width: 130, child: Text(e.viewName)),
                ))
            .toList(),
        value: themeLayout.theme,
        onChanged: (value) {
          if (value == null) return;
          themeLayout.theme = value;
        },
      ),
    ));

    return tiles;
  }

  SettingsTile timeSettingTile(BuildContext context) {
    return SettingsTile(
      title: const Text("Night Time"),
      trailing: ToggleButtons(
        constraints: const BoxConstraints(maxHeight: 50, maxWidth: 100),
        renderBorder: true,
        borderRadius: BorderRadius.circular(10),
        borderWidth: 0,
        isSelected: const [
          true,
          true,
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
    );
  }
}
