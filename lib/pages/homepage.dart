import 'dart:developer';

import 'package:carer/pages/settingspage.dart';

import 'package:carer/widgets/bgl.dart';
import 'package:carer/widgets/history.dart';
import 'package:carer/widgets/sleep.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    log("build");
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        color: Colors.black,
        height: MediaQuery.of(context).size.height,
        child: const Column(children: [
          Flexible(flex: 2, child: BGL()),
          Flexible(flex: 1, child: History()),
          Spacer(),
          Flexible(flex: 1, child: Sleep()),
        ]),
      ),
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
                    MaterialPageRoute(builder: (context) => SettingsPage()),
                  );
                })
          ],
        ),
      ),
    );
  }

  Widget historyDisplay() {
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
}
