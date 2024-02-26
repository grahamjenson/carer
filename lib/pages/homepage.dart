import 'package:carer/models/settings_cn.dart';
import 'package:carer/models/summary_cn.dart';
import 'package:carer/pages/settingspage.dart';

import 'package:carer/widgets/bgl/bgl.dart';
import 'package:carer/widgets/colours.dart';
import 'package:carer/widgets/current_time.dart';
import 'package:carer/widgets/insights/bgl_chart.dart';
import 'package:carer/widgets/insights/history.dart';
import 'package:carer/widgets/insights/stats.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final aspectRatio = MediaQuery.of(context).size.aspectRatio;
    final isWideScreen = aspectRatio > 1.0;

    return Consumer2<Settings, SummaryCN>(
        builder: (context, settings, summaryCn, child) {
      Widget insights = const SizedBox.shrink();
      if (settings.showChart && settings.showHistory) {
        insights = const Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Flexible(child: BGLChart()),
              Flexible(
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                    Flexible(child: History()),
                    Flexible(child: Stats())
                  ]))
            ]);
      } else if (settings.showChart) {
        insights = const Flexible(child: Flexible(child: BGLChart()));
      } else if (settings.showHistory) {
        insights = const Row(
            children: [Flexible(child: History()), Flexible(child: Stats())]);
      }

      var bgl = const Flexible(flex: 4, child: BGL());

      Widget mainLine = Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [bgl, Flexible(flex: 5, child: insights)]);

      if (isWideScreen) {
        mainLine = Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [bgl, Flexible(flex: 3, child: insights)]);
      }

      return Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Container(
              height: MediaQuery.of(context).size.height,
              width: MediaQuery.of(context).size.width,
              padding: const EdgeInsets.all(8),
              child: mainLine,
            ),
            const Positioned(
              top: 10, // Adjust these values as needed
              left: 10,
              child: FittedBox(child: CurrentTimeWidget()),
            ),
          ],
        ),
        bottomNavigationBar: BottomAppBar(
          color: Colors.transparent,
          padding: const EdgeInsets.only(left: 8, right: 8),
          height: 40,
          child: Row(
            children: [
              const Spacer(),
              IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(
                    Icons.settings,
                    color: mainColor,
                  ),
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
