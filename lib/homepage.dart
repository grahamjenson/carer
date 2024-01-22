import 'dart:developer';

import 'package:carer/nsclient/nsclient.dart';
import 'package:carer/nsclient/summary.dart';
import 'package:carer/settings.dart';
import 'package:carer/settingspage.dart';
import 'package:carer/snoozepage.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import 'package:slide_to_act/slide_to_act.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool summaryToBeUpdated = true;
  late Future<Summary?> futureSummary;
  late Timer timer;

  @override
  void initState() {
    super.initState();

    Settings.addSettingsChangeListener((setting, _) {
      log("Listener Setting changed: $setting");
      if (setting == SettingNames.nightscoutUrl) {
        summaryToBeUpdated = true;
      }
    });

    update();
    log("init");
    timer = Timer.periodic(const Duration(seconds: 5), (Timer t) => update());
  }

  update() {
    if (summaryToBeUpdated) {
      setState(() {
        if (summaryToBeUpdated) {
          futureSummary = NSClient().getSummary();
          summaryToBeUpdated = false;
          print("HERE I SUPPOSE");
        }
      });
    }

    futureSummary.then((value) {
      if (value == null) return;
      print("are you here");
      print(value.ageInSeconds());
      if (value.ageInSeconds() > 15) {
        print("AsdsaD");
        print(value.ageInSeconds());
        summaryToBeUpdated = true;
      }
    });
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    log("build");
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(children: [
        const Spacer(),
        bglDisplay(),
        const Spacer(),
        statsDisplay(),
        const Spacer(),
        sleepDisplay()
      ]),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          children: [
            IconButton(icon: const Icon(Icons.menu), onPressed: () {}),
            const Spacer(),
            IconButton(icon: const Icon(Icons.search), onPressed: () {}),
            IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SettingsPage()),
                  );
                })
          ],
        ),
      ),
    );
  }

  Widget bglDisplay() {
    return Container(
        height: 100,
        color: Colors.blue,
        alignment: Alignment.center,
        child: FutureBuilder<Summary?>(
          future: futureSummary,
          builder: ((context, futureSummary) {
            if (futureSummary.hasError) {
              return Text('Error: ${futureSummary.error}');
            }

            var lastSGV = futureSummary.data?.lastSGV;
            if (lastSGV == null) {
              return const CircularProgressIndicator();
            }

            return Text('DATA: ${lastSGV.sgvMmolL} ${lastSGV.dateAgo}');
          }),
        ));
  }

  Widget statsDisplay() {
    return Container(
        height: 100,
        color: Colors.red,
        alignment: Alignment.center,
        child: FutureBuilder<Summary?>(
          future: futureSummary,
          builder: ((context, futureSummary) {
            if (futureSummary.hasError) {
              return Text('Error: ${futureSummary.error}');
            }

            var lastSGV = futureSummary.data?.lastSGV;
            if (lastSGV == null) {
              return const CircularProgressIndicator();
            }

            return Text('DATA: ${lastSGV.sgvMmolL} ${lastSGV.dateAgo}');
          }),
        ));
  }

  Widget sleepDisplay() {
    return Container(
        height: 100,
        color: Colors.purple,
        alignment: Alignment.center,
        child: SlideAction(
          text: "Snnoze 1346",
          sliderRotate: false,
          onSubmit: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SnoozePage()),
            );
            return null;
          },
        ));
  }
}
