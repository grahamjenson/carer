import 'package:carer/utils/logs.dart';
import 'package:flutter/material.dart';

class LogErrorPage extends StatefulWidget {
  const LogErrorPage({super.key});

  @override
  State<LogErrorPage> createState() => _LogErrorPageState();
}

class _LogErrorPageState extends State<LogErrorPage> {
  final TextEditingController controller = TextEditingController();

  _LogErrorPageState();

  var filterString = "";
  String getFilteredLogLines() {
    String logString = ALogger().getPrettyLogs();
    return logString.split('\n').where((line) => line.contains(filterString)).join('\n');
  }

  @override
  void initState() {
    super.initState();
    // initialize the controller
    controller.addListener(() {
      setState(() => filterString = controller.text);
    });
  }

  // on destroy dispose of the controller
  @override
  void dispose() {
    controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // loop over the lines and filter out all lines without the TextButtons text
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Error Page'),
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
                getFilteredLogLines(),
                style: const TextStyle(
                  fontSize: 8,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              )),
            )
          ],
        ),
      ),
    );
  }
}
