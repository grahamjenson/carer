import 'package:carer/pages/homepage.dart';
import 'package:flutter/material.dart';

void main() {
  // print all environmnet variables
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
