import 'package:carer/models/settings_cn.dart';
import 'package:carer/models/summary_cn.dart';
import 'package:carer/pages/homepage.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() async {
  // Load the settings from Shared Preferences before starting
  var s = Settings();

  print(s.toString());
  runApp(MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => s),
        ChangeNotifierProvider(create: (context) => SummaryCN(settings: s)),
      ],
      child: FutureProvider(
        initialData: null,
        create: (context) => s.populate(),
        child: MyApp(settings: s),
      )));
}

class MyApp extends StatelessWidget {
  Settings settings;
  MyApp({super.key, required this.settings});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Carer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color.fromARGB(255, 0, 0, 0),
            brightness: Brightness.dark),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}
