import 'package:carer/change_notifiers/settings/debug_settings.dart';
import 'package:carer/change_notifiers/settings_cn.dart';
import 'package:carer/change_notifiers/update_cn.dart';
import 'package:carer/widgets/settings/debug_pages/log_error_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_settings_ui/flutter_settings_ui.dart';
import 'package:provider/provider.dart';
import 'package:unicons/unicons.dart';

class DebugSettingsWidget extends AbstractSettingsSection {
  const DebugSettingsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<SettingsCN, UpdateCN>(
        builder: (context, settings, summary, child) {
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
          SettingsTile.navigation(
            title: const Text("Log Error"),
            descriptionInlineIos: true,
            leading: const Icon(UniconsLine.bug),
            onPressed: (context) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LogErrorPage()),
              );
            },
          ),
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
