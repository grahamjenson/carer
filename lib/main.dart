import 'dart:io';

import 'package:carer/models/state_data.dart';
import 'package:carer/services/alarms_service.dart';
import 'package:carer/services/settings/settings.dart';
import 'package:carer/services/settings/ui_settings.dart';
import 'package:carer/services/timer_service.dart';
import 'package:carer/services/update_service.dart';
import 'package:carer/utils/env.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/utils/logs.dart';
import 'package:carer/widgets/pages/homepage.dart';
import 'package:flutter/material.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:workmanager/workmanager.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    alog("callbackDispatcher: background task $task EXECUTING");

    var allGood = await UpdateService().updateAll();
    if (!allGood) {
      alog("Error updating all");
    }

    return Future.value(true);
  });
}

void main() async {
  //databaseFactory = databaseFactory.debugQuickLoggerWrapper();

  await SentryFlutter.init(
    (options) {
      options.dsn = 'https://635c475aa48824327a23e3723e92a278@o4507178414243840.ingest.us.sentry.io/4507178416996352';
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
  if (Platform.isIOS || Platform.isAndroid) {
    Workmanager().initialize(callbackDispatcher, // The top level function, aka callbackDispatcher
        isInDebugMode: true // If enabled it will post a notification whenever the task is running. Handy for debugging tasks
        );

    Workmanager().registerPeriodicTask(
      "nz.t1d.carer.updateValues",
      "nz.t1d.carer.updateValues",
      frequency: const Duration(minutes: 15),
      initialDelay: const Duration(seconds: 10),
    );
  }

  WidgetsFlutterBinding.ensureInitialized();

  // Load the settings from Shared Preferences before starting
  var settings = Settings();
  await settings.setupDBPropagation();

  // Setup the StateData DB stuff
  await StateData().setupDBPropagation();

  // For some reason screens forget to stay awake
  aeffect(() {
    var _ = TimerService().fifteenSecondSignal.value;
    if (!Env.isTest) {
      WakelockPlus.toggle(enable: UISettings().screenActive);
    }
  }, debugLabel: "WakelockPlus");

  UpdateService().start();
  AlarmsService();

  runApp(const MyApp());
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
          colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 0, 50, 0), brightness: Brightness.dark),
          useMaterial3: true,
        ),
        home: const HomePage(),
      ),
    );
  }
}
