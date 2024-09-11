import 'package:carer/services/timer_service.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/utils/logs.dart';
import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';

class LogErrorPage extends StatefulWidget {
  const LogErrorPage({super.key});

  @override
  State<LogErrorPage> createState() => _LogErrorPageState();
}

class _LogErrorPageState extends State<LogErrorPage> {
  final TextEditingController controller = TextEditingController();

  final Signal<String> text = Signal<String>('');
  late Computed<String> predictionsSignal;

  _LogErrorPageState() {
    controller.addListener(() {
      text.value = controller.text;
    });
    predictionsSignal = acomputed(() {
      String logString = ALogger().getPrettyLogs();
      return logString.split('\n').where((line) => line.contains(text.value)).join('\n');
    }, "", debugLabel: "DebugLogErrorPage", dependencies: [TimerService().secondSignal]);
  }

  // on destroy dispose of the controller
  @override
  void dispose() {
    controller.dispose();
    text.dispose();
    predictionsSignal.dispose();
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
              child: AWatch((_) {
                return SingleChildScrollView(
                    child: SelectableText(
                  predictionsSignal.value,
                  style: const TextStyle(
                    fontSize: 8,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ));
              }),
            )
          ],
        ),
      ),
    );
  }
}
