import 'package:carer/models/settings/debug_settings.dart';
import 'package:carer/models/settings_cn.dart';
import 'package:flutter/material.dart';
import 'package:flutter_settings_ui/flutter_settings_ui.dart';
import 'package:provider/provider.dart';
import 'package:unicons/unicons.dart';

class DebugSettingsWidget extends AbstractSettingsSection {
  const DebugSettingsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<Settings>(builder: (context, settings, child) {
      var debugSettings = [];
      if (settings.debug) {
        // Add debugSummary Selector
        debugSettings.add(SettingsTile(
          title: Row(children: [
            const Text('Debug Summary'),
            Container(
                alignment: Alignment.centerRight,
                child: DropdownButton(
                  value: settings.debugSummary,
                  onChanged: (DebugSummary? value) {
                    if (value == null) return;
                    settings.debugSummary = value;
                  },
                  items: DebugSummary.values
                      .map<DropdownMenuItem<DebugSummary>>((e) {
                    return DropdownMenuItem<DebugSummary>(
                      value: e,
                      child: Text(e.name),
                    );
                  }).toList(),
                ))
          ]),
        ));
      }

      return SettingsSection(
        title: const Text('Debug'),
        tiles: [
          SettingsTile.switchTile(
            title: const Text('Debug'),
            initialValue: settings.debug,
            leading: const Icon(UniconsLine.bug),
            onToggle: (value) async {
              settings.debug = value;
            },
          ),
          ...debugSettings,
        ],
      );
    });
  }
}
