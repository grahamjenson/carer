// Runs each UI flow (README.md) here, with no device
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../tool/bundle_flows.dart';
import 'runner.dart';

void main() {
  // Real time, as on a device
  LiveTestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  FlutterSecureStorage.setMockInitialValues({});
  // A phone's notifications, as a test is Android's, which do nothing here
  AndroidFlutterLocalNotificationsPlugin.registerWith();
  const notifications = MethodChannel("dexterous.com/flutter/local_notifications");
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(notifications,
      (call) async {
    return call.method == "initialize" ? true : null;
  });

  // The fonts a phone has, rather than the tests' font of squares: the app's, its icons', and Roboto, as on Android, for
  // text as wide as on a phone. Text that names no font, as the care page's buttons, is still squares
  setUpAll(() async {
    var sdkFonts = File(Platform.resolvedExecutable).parent.parent.parent.path;
    var roboto = ["Regular", "Medium", "Bold"].map((weight) => "$sdkFonts/material_fonts/Roboto-$weight.ttf");
    var fonts = <String, Iterable<Future<ByteData>>>{
      "Roboto": roboto.map((path) async => ByteData.sublistView(File(path).readAsBytesSync())),
      for (var family in jsonDecode(await rootBundle.loadString("FontManifest.json")))
        family["family"]: [for (var font in family["fonts"]) rootBundle.load(font["asset"])],
    };
    for (var MapEntry(key: family, value: files) in fonts.entries) {
      await files.fold(FontLoader(family), (loader, file) => loader..addFont(file)).load();
    }
  });

  var files = {
    for (var f in Directory(flowsDir).listSync(recursive: true).whereType<File>())
      f.path.substring(flowsDir.length + 1): f.readAsStringSync(),
  };
  for (var path in files.keys.where((p) => p.endsWith(".bdd")).toList()..sort()) {
    testWidgets(path, (tester) async {
      // A phone's screen, 390 by 844
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await runFlow(tester, path, files, screenshot: (name) async {
        // build/flows/<flow>/<name>.png, of the screen as drawn
        var layer = tester.binding.renderViews.first.debugLayer! as OffsetLayer;
        var image = await layer.toImage(Offset.zero & tester.view.physicalSize);
        var png = await image.toByteData(format: ImageByteFormat.png);
        var file = File("build/flows/${path.replaceAll(".bdd", "")}/$name.png")..createSync(recursive: true);
        file.writeAsBytesSync(png!.buffer.asUint8List());
      });
    });
  }

  test("$bundlePath has the flows, as dart run tool/bundle_flows.dart writes them", () {
    expect(File(bundlePath).readAsStringSync(), bundleFlows());
  });
}
