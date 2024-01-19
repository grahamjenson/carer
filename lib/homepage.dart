import 'dart:io';

import 'package:carer/nsclient/entries.dart';

import 'package:carer/nsclient/nsclient.dart';
import 'package:carer/settingspage.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<Entries?> futureEntries;

  @override
  void initState() {
    super.initState();

    futureEntries = NSClient().getEntries();

    const oneSecond = Duration(seconds: 25);
    Timer.periodic(oneSecond, (Timer t) {
      print("DATA REFRESH1");
      setState(() {
        print("DATA REFRESH2");
        futureEntries = NSClient().getEntries();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('TITITITITILE'), actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.add_alert),
            tooltip: 'Show Snackbar',
            onPressed: () {
              print("PUSHED");
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          )
        ]),
        body: Center(
          child: FutureBuilder<Entries?>(
            future: futureEntries,
            builder: ((context, snapshot) {
              if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              }

              var entries = snapshot.data;
              if (entries == null || entries.isEmpty()) {
                return const CircularProgressIndicator();
              }

              var first = entries.firstOrNull();
              if (first == null) {
                return const CircularProgressIndicator();
              }

              print('PRINTING DATA: ${first.sgv! / 18}');
              return Text('DATA: ${first.sgv! / 18}');
            }),
          ),
        ));
  }
}
