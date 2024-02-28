import 'package:carer/models/alarms_cn.dart';
import 'package:carer/models/settings_cn.dart';
import 'package:carer/models/summary_cn.dart';
import 'package:carer/pages/homepage.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load the settings from Shared Preferences before starting
  var settings = Settings();
  await settings.populate();

  if (settings.screenActive) {
    await WakelockPlus.enable();
  } else {
    await WakelockPlus.disable();
  }

  final summary = SummaryCN(settings: settings);
  final alarms = AlarmsChangeNotifier(settings: settings, summaryCn: summary);

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (context) => settings),
      ChangeNotifierProvider(create: (context) => summary),
      ChangeNotifierProvider(create: (context) => alarms),
    ],
    child: MyApp(settings: settings),
  ));
}

class MyApp extends StatelessWidget {
  final Settings settings;
  const MyApp({super.key, required this.settings});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Carer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color.fromARGB(255, 0, 50, 0),
            brightness: Brightness.dark),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}
