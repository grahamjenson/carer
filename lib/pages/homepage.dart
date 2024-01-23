import 'dart:developer';

import 'package:carer/nsclient/nsclient.dart';
import 'package:carer/nsclient/summary.dart';
import 'package:carer/models/settings.dart';
import 'package:carer/pages/settingspage.dart';
import 'package:carer/pages/snoozepage.dart';
import 'package:carer/utils/dates.dart';
import 'package:carer/widgets/bgl.dart';
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
  Summary summary = Summary.empty();
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
    if (summary.ageInSeconds() > 15) {
      summaryToBeUpdated = true;
    }

    if (summaryToBeUpdated) {
      summaryToBeUpdated = false;
      NSClient().getSummary().catchError((e) {
        log("GETTING SUMMARY ERROR: $e");
        summaryToBeUpdated = true;
        return Summary.empty();
      }).then((value) {
        if (value.dateRetrieved == Dates.earliest) {
          return;
        }
        setState(() {
          summary = value;
        });
      });
    }
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
        BGL(summary: summary),
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

  Widget statsDisplay() {
    return Container(
        height: 100,
        color: Colors.red,
        alignment: Alignment.center,
        child: Builder(
          builder: ((context) {
            if (summary.dateRetrieved == Dates.earliest) {
              return const CircularProgressIndicator();
            }

            var lastSGV = summary.lastSGV;
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
