import 'dart:io';

import 'package:carer/mappers/sql/events.dart';
import 'package:carer/models/clean_sgv.dart';
import 'package:carer/models/flow_data.dart';
import 'package:carer/models/sql/sgv.dart';
import 'package:carer/models/treatment_group.dart';
import 'package:carer/models/valueAtTime.dart';
import 'package:carer/services/alarms_service.dart';
import 'package:carer/services/app_lifecycle_service.dart';
import 'package:carer/services/background_service.dart';
import 'package:carer/services/notification_service.dart';
import 'package:carer/services/prediction_service.dart';
import 'package:carer/services/settings/secure_settings.dart';
import 'package:carer/services/settings/settings.dart';
import 'package:carer/services/settings/ui_settings.dart';
import 'package:carer/services/themes_service.dart';
import 'package:carer/services/timer_service.dart';
import 'package:carer/services/update_service.dart';
import 'package:carer/sql/key_value_store.dart';
import 'package:carer/utils/asentry_http_client.dart';
import 'package:carer/utils/carer_http.dart';
import 'package:carer/utils/env.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/utils/logs.dart';
import 'package:carer/utils/strings.dart';
import 'package:carer/widgets/router.dart';
import 'package:clock/clock.dart';
import 'package:desktop_window/desktop_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:toastification/toastification.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

void main() async {
  await SentryFlutter.init(
    sentryOptions,
    appRunner: () => runCarer(),
  );
}

void runCarer() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isMacOS || Platform.isLinux || Platform.isWindows) {
    await DesktopWindow.setMinWindowSize(const Size(300, 450));
  }

  StringAssets().loadStrings();

  // Signals logging
  setupSignalsLogging();

  await executeWithRetry(() async {
    alog("Initilize Logging");
  });

  // Execute with retry setting up and initializing instances of the DB
  await executeWithRetry(() async {
    // Key value store in another db
    var prefs = await KeyValueStore.instance;
    await prefs.internalPopulate();
  });

  await executeWithRetry(
    () async {
      // Setup secure storage for settings
      await SecureSettings().readAll();
      await SecureSettings().migrateOldStore();
    },
    maxRetries: 10,
  );

  // Load the settings from Shared Preferences before starting
  await Settings().setupDBPropagation();

  await FlowData().setupDBPropagation();

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

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

  await CleanSGV.setupSQLSignals();
  await Treatment.setupSQLSignals();
  await ValueAtTime.setupSQLSignals();
  await SGV.setupSQLSignals();
  await SQLToEvents().setupSQLSignals();

  if (Platform.isIOS || Platform.isAndroid) {
    await BackgroundService().configure();
    await BackgroundService().start();
  }

  runApp(const MyApp());

  if (Platform.isAndroid) {
    await BackgroundService().registerHeadlessTask();
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with ThemeMixin {
  @override
  Widget build(BuildContext context) {
    return ListenForInteraction(
      child: ValueListenableBuilder<ThemeData>(
        valueListenable: ThemeService().themeNotifier,
        builder: (context, theme, _) {
          final landscape = MediaQuery.of(context).size.aspectRatio > 1.0;
          if (landscape) {
            UISettings().orientation = Orientation.landscape;
          } else {
            UISettings().orientation = Orientation.portrait;
          }

          return ToastificationWrapper(
            child: MaterialApp.router(
              title: 'Carer',
              debugShowCheckedModeBanner: false,
              theme: theme,
              routerConfig: getRouter(),
            ),
          );
        },
      ),
    );
  }
}

class ListenForInteraction extends StatelessWidget {
  final Widget child;

  const ListenForInteraction({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: (_) {
        AppLifecycleService().lastInteraction.value = clock.now();
      },
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) {
          AppLifecycleService().lastInteraction.value = clock.now();
        },
        child: child,
      ),
    );
  }
}

void sentryOptions(SentryFlutterOptions options) {
  options.dsn = 'https://635c475aa48824327a23e3723e92a278@o4507178414243840.ingest.us.sentry.io/4507178416996352';
  // Set tracesSampleRate to 1.0 to capture 100% of transactions for performance monitoring.
  // We recommend adjusting this value in production.
  options.tracesSampleRate = 1.0;
  // The sampling rate for profiling is relative to tracesSampleRate
  // Setting to 1.0 will profile 100% of sampled transactions:
  options.profilesSampleRate = 1.0;

  options.httpClient = CarerHttp.getClient();

  options.debug = Env.isDev;

  options.beforeSend = (SentryEvent event, Hint hint) {
    final exception = event.throwable;
    for (var ig in ignoredExceptions) {
      if (exception != null && exception.message.contains(ig)) {
        return null; // Drop the event
      }
    }

    return event;
  };

  // I don't want to know the URL of NSClients
  options.beforeBreadcrumb = (Breadcrumb? breadcrumb, Hint hint) {
    if (breadcrumb == null) {
      return null; // nothgin in nothign out
    }

    // This stops some leaks from sentry sending host and query params out!!!
    if (breadcrumb.type == 'http' && breadcrumb.data != null) {
      for (var key in breadcrumb.data!.keys.toList()) {
        var val = breadcrumb.data![key];
        if (val is String) {
          breadcrumb.data![key] = ALogger().censorLogs(val);
        }
      }
    }

    return breadcrumb; // Keep the breadcrumb
  };
}
