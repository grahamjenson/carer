import 'package:carer/models/settings_cn.dart';
import 'package:carer/models/summary_cn.dart';
import 'package:carer/widgets/bar.dart';
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

    return Consumer2<Settings, SummaryCN>(
        builder: (context, settings, summaryCn, child) {
      var insights = getInsights(settings);
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
        body: SafeArea(
            child: Stack(
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
        )),
        bottomNavigationBar: const Bar(),
      );
    });
  }

  Widget getInsights(Settings settings) {
    bool showHistory = settings.uiSettings.showHistory;
    bool showStats = settings.uiSettings.showStats;
    bool showChart = settings.uiSettings.showChart;

    if (!showHistory && !showStats && !showChart) {
      return const SizedBox.shrink();
    }
    var tables = [
      if (showHistory) const Expanded(child: History()),
      if (showStats) const Expanded(child: Stats()),
    ];
    if (showChart) {
      var children = [const Flexible(child: BGLChart())];
      if (showHistory || showStats) {
        children.add(Flexible(
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: tables)));
      }
      return Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround, children: children);
    } else {
      return Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround, children: tables);
    }
  }
}
