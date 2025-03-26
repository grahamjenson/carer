import 'package:carer/services/share_file_service.dart';
import 'package:carer/services/ui/icons.dart';
import 'package:carer/utils/env.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_settings_ui/flutter_settings_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutSettingsWidget extends AbstractSettingsSection {
  const AboutSettingsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsSection(
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
                  applicationVersion: Env.version,
                  applicationIcon: const Icon(CarerIcons.SETTINGS_ABOUT),
                  applicationLegalese: "© 2025 Carer",
                  children: <Widget>[
                    const Text("Carer is a diabetes management app"),
                  ]);
            }),
        SettingsTile.navigation(
          title: const Text("Contact"),
          leading: const Icon(CarerIcons.SETTINGS_CONTACT),
          onPressed: (context) async {
            String? encodeQueryParameters(Map<String, String> params) {
              return params.entries.map((MapEntry<String, String> e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}').join('&');
            }

            final Uri emailLaunchUri = Uri(
              scheme: 'mailto',
              path: 'contact@t1d.nz',
              query: encodeQueryParameters(<String, String>{
                'subject': 'Carer (v${Env.version}) App Contact',
                'body': "Hi, I have a question/comment/feature request for Carer...\n DO NOT SHARE PASSWORDS NIGHTSCOUT LINKS OR TOKENS HERE",
              }),
            );

            // This is async but we just ignore return
            launchUrl(emailLaunchUri);
          },
        ),
        SettingsTile.navigation(
          title: const Text("Share All Data"),
          description: const Text("Send to contact@t1d.nz"),
          descriptionInlineIos: true,
          leading: const Icon(CarerIcons.SETTINGS_DEBUG),
          onPressed: (BuildContext context) async {
            ShareFileService().shareFiles();
          },
        ),
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
                  GoRouter.of(context).pop();
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
