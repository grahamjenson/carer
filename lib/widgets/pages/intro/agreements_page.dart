import 'package:carer/models/flow_data.dart';
import 'package:carer/services/themes_service.dart';
import 'package:carer/utils/strings.dart';
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart';

class AgreementsPage extends StatelessWidget with ThemeMixin {
  const AgreementsPage({super.key});

  @override
  Widget build(BuildContext context) {
    ButtonStyle btnStyle = ButtonStyle(
      backgroundColor: WidgetStateProperty.all<Color>(accentColor(context).dim.dim.dim),
      padding: WidgetStateProperty.all<EdgeInsetsGeometry>(const EdgeInsets.all(20)),
      textStyle: WidgetStateProperty.all<TextStyle>(
        const TextStyle(
          fontSize: 30,
        ),
      ),
      shape: WidgetStateProperty.all<RoundedRectangleBorder>(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
      ),
      side: WidgetStateProperty.all<BorderSide>(
        BorderSide(color: accentColor(context).dim.dim, width: 1), // Change border color here
      ),
    );

    return Container(
      padding: const EdgeInsets.all(40),
      child: SingleChildScrollView(
        child: Column(
          children: [
            MarkdownBody(
              data: StringAssets().termsOfService,
              styleSheet: MarkdownStyleSheet.fromTheme(
                Theme.of(context).copyWith(
                  textTheme: Theme.of(context).textTheme.apply(fontSizeFactor: 0.5),
                ),
              ),
            ),
            const Divider(),
            MarkdownBody(
              data: StringAssets().privacyPolicy,
              styleSheet: MarkdownStyleSheet.fromTheme(
                Theme.of(context).copyWith(
                  textTheme: Theme.of(context).textTheme.apply(fontSizeFactor: 0.5),
                ),
              ),
            ),
            ElevatedButton(
              style: btnStyle,
              onPressed: () {
                FlowData().agreedTermsOfServicePrivacy = clock.now();

                GoRouter.of(context).go('/display');
              },
              child: const Text("Accept"),
            ),
          ],
        ),
      ),
    );
  }
}
