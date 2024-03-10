import 'package:carer/models/settings_cn.dart';
import 'package:carer/widgets/settings/togglebutton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_settings_ui/flutter_settings_ui.dart';
import 'package:provider/provider.dart';
import 'package:unicons/unicons.dart';

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
            title: const Text("Boundary Alarms"),
            trailing: ToggleButtons(
              isSelected: [
                settings.uiSettings.showChart,
                settings.uiSettings.showHistory,
                settings.uiSettings.showStats,
              ],
              onPressed: (int index) {
                switch (index) {
                  case 0:
                    settings.uiSettings.showChart =
                        !settings.uiSettings.showChart;
                    break;
                  case 1:
                    settings.uiSettings.showHistory =
                        !settings.uiSettings.showHistory;
                    break;
                  case 2:
                    settings.uiSettings.showStats =
                        !settings.uiSettings.showStats;
                    break;
                }
              },
              children: const [
                ToggleButton(text: "Chart", icon: UniconsLine.chart_line),
                ToggleButton(text: "History", icon: UniconsLine.history),
                ToggleButton(text: "Stats", icon: UniconsLine.chart_pie_alt),
              ],
            ),
          ),
        ],
      );
    });
  }
}
