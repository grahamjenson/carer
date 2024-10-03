import 'dart:io';

import 'package:carer/models/clean_sgv.dart';
import 'package:carer/models/properties_data.dart';
import 'package:carer/models/sql/profile.dart';
import 'package:carer/models/sql/sgv.dart';
import 'package:carer/models/treatment_group.dart';
import 'package:carer/models/valueAtTime.dart';
import 'package:carer/services/alarms_service.dart';
import 'package:carer/services/app_lifecycle_service.dart';
import 'package:carer/services/background_service.dart';
import 'package:carer/services/notification_service.dart';
import 'package:carer/services/prediction_service.dart';
import 'package:carer/services/settings/settings.dart';
import 'package:carer/services/settings/ui_settings.dart';
import 'package:carer/services/themes_service.dart';
import 'package:carer/services/timer_service.dart';
import 'package:carer/services/update_service.dart';
import 'package:carer/utils/env.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/widgets/pages/homepage.dart';
import 'package:desktop_window/desktop_window.dart';
import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

void main() async {
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
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isMacOS || Platform.isLinux || Platform.isWindows) {
    await DesktopWindow.setMinWindowSize(const Size(450, 450));
  }

  // Signals logging
  setupSignalsLogging();

  // Load the settings from Shared Preferences before starting
  await executeWithRetry(Settings().setupDBPropagation);

  // Setup the StateData DB stuff
  await executeWithRetry(PropertiesData().setupDBPropagation);

  // For some reason screens forget to stay awake
  aeffect(() {
    var _ = TimerService().fifteenSecondSignal.value;
    if (!Env.isTest) {
      WakelockPlus.toggle(enable: UISettings().screenActive);
    }
  }, debugLabel: "WakelockPlus");

  ////
  // SERVICES
  ////

  AppLifecycleService();
  NotificationService();
  UpdateService().start();
  AlarmsService();
  ThemeService();
  PredictionService();

  ////
  // SQL Signals
  ////

  CleanSGV.setupSQLSignals();
  Profile.setupSQLSignals();
  Treatment.setupSQLSignals();
  ValueAtTime.setupSQLSignals();
  SGV.setupSQLSignals();

  runApp(const MyApp());

  if (Platform.isIOS || Platform.isAndroid) {
    BackgroundService();
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeData>(
        valueListenable: ThemeService().themeNotifier,
        builder: (context, theme, _) {
          return MaterialApp(
            navigatorObservers: [NavigationChangeObserver(), SentryNavigatorObserver()],
            title: 'Carer',
            debugShowCheckedModeBanner: false,
            theme: theme,
            home: const HomePage(),
            initialRoute: '/',
          );
        });
  }
}
