import 'package:carer/services/ui/icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_settings_ui/flutter_settings_ui.dart';

class AboutSettingsWidget extends AbstractSettingsSection {
  const AboutSettingsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsSection(
      title: const Text('About'),
      tiles: [
        SettingsTile.navigation(
            title: const Text("About"),
            leading: const Icon(CarerIcons.SETTINGS_ABOUT),
            descriptionInlineIos: true,
            description: const Text("About Carer"),
            onPressed: (context) async {
              showAboutDialog(
                  context: context,
                  applicationName: "Carer",
                  applicationVersion: "0.0.1",
                  applicationIcon: const Icon(CarerIcons.SETTINGS_ABOUT),
                  applicationLegalese: "© 2021 Carer",
                  children: <Widget>[
                    const Text("Carer is a diabetes management app"),
                  ]);
            }),
      ],
    );
  }

  Future<void> showDocument(BuildContext context, String documentName, String document) async {
    await showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(documentName),
            scrollable: false,
            content: SingleChildScrollView(
              child: MarkdownBody(
                data: document,
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Close'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        });
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) {
      return "Unknown";
    }
    return "${dt.year}-${dt.month}-${dt.day}";
  }
}
