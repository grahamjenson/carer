import 'package:carer/change_notifiers/settings_cn.dart';
import 'package:carer/utils/json.dart';
import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class LogErrorPage extends StatelessWidget {
  LogErrorPage({super.key});

  final TextEditingController controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    var settingsString = prettyPrintJson(Settings().toString());
    var summaryString = "TODO: dump the db here";

    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Error'),
        actions: [
          TextButton(
            child: const Text("Log"),
            onPressed: () async {
              await Sentry.captureMessage(
                "ContextError: ${controller.text}",
                withScope: (scope) {
                  scope.setContexts('settings', settingsString);
                  scope.setContexts('summary', summaryString);
                },
              ).then((value) => Navigator.pop(context));
            },
          ),
        ],
      ),
      body: Container(
        margin: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Enter error message',
              ),
            ),
            Expanded(
                child: SingleChildScrollView(
              child: SelectableText(
                '$settingsString\n\n$summaryString',
                style: const TextStyle(fontSize: 8),
              ),
            )),
          ],
        ),
      ),
    );
  }
}
