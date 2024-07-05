import 'package:carer/services/settings/settings.dart';
import 'package:carer/utils/json.dart';
import 'package:carer/utils/logs.dart';
import 'package:flutter/material.dart';

class LogErrorPage extends StatelessWidget {
  LogErrorPage({super.key});

  final TextEditingController controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    var settingsString = prettyPrintJson(Settings().toString());
    var logString = ALogger().getPrettyLogs();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
        actions: [
          TextButton(
            child: const Text("Search"),
            onPressed: () async {},
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
                '$settingsString\n\n$logString',
                style: const TextStyle(fontSize: 8),
              ),
            )),
          ],
        ),
      ),
    );
  }
}
