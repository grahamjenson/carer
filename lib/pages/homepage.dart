import 'dart:developer';

import 'package:carer/nsclient/nsclient.dart';
import 'package:carer/nsclient/summary.dart';
import 'package:carer/models/settings_cn.dart';
import 'package:carer/pages/settingspage.dart';
import 'package:carer/pages/snoozepage.dart';
import 'package:carer/utils/dates.dart';
import 'package:carer/widgets/bgl.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import 'package:slide_to_act/slide_to_act.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    log("build");
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(children: [
        const BGL(),
        statsDisplay(),
        const Spacer(),
        sleepDisplay(context)
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
            return const Text('DATA:');
          }),
        ));
  }

  Widget sleepDisplay(BuildContext context) {
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
