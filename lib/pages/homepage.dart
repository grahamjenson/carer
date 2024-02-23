import 'dart:developer';

import 'package:carer/models/settings_cn.dart';
import 'package:carer/models/summary_cn.dart';
import 'package:carer/pages/settingspage.dart';

import 'package:carer/widgets/bgl/bgl.dart';
import 'package:carer/widgets/current_time.dart';
import 'package:carer/widgets/insights/history.dart';
import 'package:carer/widgets/insights/stats.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<Settings, SummaryCN>(
        builder: (context, settings, summaryCn, child) {
      List<Widget> sections = [
        const Flexible(flex: 4, child: BGL()),
      ];

      if (settings.showHistory) {
        sections.add(
          Flexible(
            flex: 2,
            child: Container(
              alignment: Alignment.center,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [History(), Stats()],
              ),
            ),
          ),
        );
      }
      return Scaffold(
        backgroundColor: Colors.black,
        body: Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          padding: const EdgeInsets.all(8),
          child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: sections),
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
    });
  }
}
