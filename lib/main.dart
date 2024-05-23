import 'package:carer/change_notifiers/alarms_cn.dart';
import 'package:carer/change_notifiers/settings_cn.dart';
import 'package:carer/change_notifiers/t1d_cn.dart';
import 'package:carer/change_notifiers/update_cn.dart';
import 'package:carer/widgets/pages/homepage.dart';
import 'package:flutter/material.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

void main() async {
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
  var settings = SettingsCN();
  await settings.populate();

  // Make sure screen wont fall asleep if set
  WakelockPlus.toggle(enable: settings.screenActive);

  final summary = UpdateCN(settings: settings);
  final t1d = T1DCN(settings: settings, summaryCn: summary);
  final alarms = AlarmsCN(t1d: t1d, settings: settings);

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (context) => settings),
      ChangeNotifierProvider(create: (context) => summary),
      ChangeNotifierProvider(create: (context) => alarms),
      ChangeNotifierProvider(create: (context) => t1d),
    ],
    child: MyApp(settings: settings),
  ));
}

class MyApp extends StatelessWidget {
  final SettingsCN settings;
  const MyApp({super.key, required this.settings});

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
