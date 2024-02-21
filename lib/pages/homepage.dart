import 'dart:developer';

import 'package:carer/pages/settingspage.dart';

import 'package:carer/widgets/bgl/bgl.dart';
import 'package:carer/widgets/current_time.dart';
import 'package:carer/widgets/insights/history.dart';
import 'package:carer/widgets/insights/insights.dart';
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
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        padding: const EdgeInsets.all(8),
        child: const Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Flexible(flex: 4, child: BGL()),
              //Flexible(flex: 4, child: Insights()),
            ]),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          children: [
            const FittedBox(child: CurrentTimeWidget()),
            const Spacer(),
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
}
