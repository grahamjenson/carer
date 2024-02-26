import 'package:carer/models/settings_cn.dart';
import 'package:carer/models/summary_cn.dart';
import 'package:carer/pages/settingspage.dart';

import 'package:carer/widgets/bgl/bgl.dart';
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

    if (isWideScreen) {}
    return Consumer2<Settings, SummaryCN>(
        builder: (context, settings, summaryCn, child) {
      List<Widget> sections = [
        const Flexible(flex: 4, child: BGL()),
      ];

      if (settings.showChart) {
        sections.add(const Flexible(flex: 2, child: BGLChart()));
      }

      if (settings.showHistory) {
        List<Widget> history = const [
          Flexible(child: History()),
          Flexible(child: Stats())
        ];

        Widget insights = Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: history);
        if (isWideScreen) {
          insights = Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: history,
          );
        }
        sections.add(
          Flexible(
            flex: 2,
            child: Container(alignment: Alignment.center, child: insights),
          ),
        );
      }

      Widget mainLine = Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround, children: sections);

      if (isWideScreen) {
        mainLine = Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: sections);
      }

      return Scaffold(
        backgroundColor: Colors.black,
        body: Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          padding: const EdgeInsets.all(8),
          child: mainLine,
        ),
        bottomNavigationBar: BottomAppBar(
          height: 50,
          child: Row(
            children: [
              const FittedBox(child: CurrentTimeWidget()),
              const Spacer(),
              IconButton(
                  padding: EdgeInsets.zero,
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
