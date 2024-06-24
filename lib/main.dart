import 'dart:async';

import 'package:carer/signals/alarms_cn.dart';
import 'package:carer/signals/settings.dart';
import 'package:carer/signals/settings/ui_settings.dart';
import 'package:carer/signals/t1d_cn.dart';
import 'package:carer/signals/update_cn.dart';
import 'package:carer/widgets/pages/homepage.dart';
import 'package:flutter/material.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

void main() async {
  //databaseFactory = databaseFactory.debugQuickLoggerWrapper();

  await SentryFlutter.init(
    (options) {
      options.dsn =
          'https://635c475aa48824327a23e3723e92a278@o4507178414243840.ingest.us.sentry.io/4507178416996352';
      // Set tracesSampleRate to 1.0 to capture 100% of transactions for performance monitoring.
      // We recommend adjusting this value in production.
      options.tracesSampleRate = 0.001;
      // The sampling rate for profiling is relative to tracesSampleRate
      // Setting to 1.0 will profile 100% of sampled transactions:
      options.profilesSampleRate = 0.001;
    },
    appRunner: () => runCarer(),
  );
}

void runCarer() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load the settings from Shared Preferences before starting
  var settings = Settings();
  await settings.setupDBPropagation();

  Timer.periodic(const Duration(seconds: 15),
      (Timer t) => WakelockPlus.toggle(enable: UISettings().screenActive));

  final summary = UpdateCN();
  final t1d = T1DCN(summaryCn: summary);
  final alarms = AlarmsCN(t1d: t1d);

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (context) => summary),
      ChangeNotifierProvider(create: (context) => alarms),
      ChangeNotifierProvider(create: (context) => t1d),
    ],
    child: const MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return OverlaySupport.global(
      child: MaterialApp(
        title: 'Carer',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
              seedColor: const Color.fromARGB(255, 0, 50, 0),
              brightness: Brightness.dark),
          useMaterial3: true,
        ),
        home: const HomePage(),
      ),
    );
  }
}
