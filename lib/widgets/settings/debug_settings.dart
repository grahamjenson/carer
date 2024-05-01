import 'package:carer/models/settings/debug_settings.dart';
import 'package:carer/models/settings_cn.dart';
import 'package:carer/models/summary_cn.dart';
import 'package:flutter/material.dart';
import 'package:flutter_settings_ui/flutter_settings_ui.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:unicons/unicons.dart';

class DebugSettingsWidget extends AbstractSettingsSection {
  const DebugSettingsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<Settings, SummaryCN>(
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
          SettingsTile(
            title: const Text("Log Error with Context"),
            descriptionInlineIos: true,
            trailing: TextButton(
              onPressed: () async {
                try {
                  throw Exception("Error with context");
                } catch (exception, stackTrace) {
                  await Sentry.captureException(
                    exception,
                    stackTrace: stackTrace,
                    hint: Hint.withMap({
                      'settings': settings,
                      'summary': summary,
                    }),
                  );
                }
              },
              child: const Text("Log"),
            ),
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
