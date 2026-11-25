// Runs each UI flow (test/flows/README.md) on an iPhone, an Android phone or a Mac:
// flutter test integration_test -d <device>
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/flows/runner.dart';
import 'flows.g.dart';

void main() {
  var binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  var converted = false;

  for (var path in flowFiles.keys.where((p) => p.endsWith(".bdd"))) {
    testWidgets(path, (tester) async {
      await runFlow(tester, path, flowFiles, screenshot: (name) async {
        // Only phones take screenshots here. Android draws the app to a surface a screenshot cannot read until it is
        // converted, once
        if (!Platform.isAndroid && !Platform.isIOS) return;
        if (Platform.isAndroid && !converted) await binding.convertFlutterSurfaceToImage();
        converted = true;
        await tester.pump();
        await binding.takeScreenshot("${path.replaceAll(".bdd", "")}/$name");
      });
    });
  }
}
