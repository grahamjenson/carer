import 'package:carer/models/flow_data.dart';
import 'package:carer/services/ui/icons.dart';
import 'package:carer/utils/strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_settings_ui/flutter_settings_ui.dart';
import 'package:go_router/go_router.dart';

class DocumentsSettingsWidget extends AbstractSettingsSection {
  const DocumentsSettingsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsSection(
      title: const Text('Documents'),
      tiles: [
        SettingsTile.navigation(
          title: const Text("Terms of Service & Privacy Policy"),
          descriptionInlineIos: true,
          description: Text("Agreed on ${_formatDate(FlowData().agreedTermsOfServicePrivacy)}"),
          leading: const Icon(CarerIcons.SETTINGS_TERMS_OF_SERVICE),
          onPressed: (BuildContext context) async {
            await showDocument(context, "Terms of Service", StringAssets().termsOfService);
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
