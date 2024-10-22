import 'package:carer/models/flow_data.dart';
import 'package:carer/utils/strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_settings_ui/flutter_settings_ui.dart';
import 'package:unicons/unicons.dart';

class TermsAndConditionsPrivacyPolicyWidget extends AbstractSettingsSection {
  const TermsAndConditionsPrivacyPolicyWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsSection(
      title: const Text('Documents'),
      tiles: [
        SettingsTile.navigation(
          title: const Text("Terms and Conditions"),
          descriptionInlineIos: true,
          description: Text("Agreed on ${_formatDate(FlowData().agreedTermsAndConditions)}"),
          leading: const Icon(UniconsLine.document_info),
          onPressed: (BuildContext context) async {
            await showDocument(context, "Terms and Conditions", StringAssets().termsAndConditions);
          },
        ),
        SettingsTile.navigation(
            title: const Text("Privacy Policy"),
            leading: const Icon(UniconsLine.document_info),
            descriptionInlineIos: true,
            description: Text("Agreed on ${_formatDate(FlowData().agreedPrivacyPolicy)}"),
            onPressed: (context) async {
              await showDocument(context, "Privacy Policy", StringAssets().privacyPolicy);
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
