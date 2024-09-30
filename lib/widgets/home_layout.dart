import 'dart:math';

import 'package:carer/services/settings/alarm_settings.dart';
import 'package:carer/services/settings/ui_settings.dart';
import 'package:carer/services/themes_service.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/widgets/alarms/snoozebutton.dart';
import 'package:carer/widgets/bgl/bgl.dart';
import 'package:carer/widgets/insights/bgl_chart.dart';
import 'package:carer/widgets/insights/history.dart';
import 'package:carer/widgets/insights/stats.dart';
import 'package:flutter/material.dart';

class HomeLayout extends StatelessWidget with ThemeMixin {
  HomeLayout({super.key});

  @override
  Widget build(BuildContext context) {
    // This needs hardcoding because the scrollable outer widget

    return LayoutBuilder(builder: (context, constraints) {
      double minHeight = max(400, constraints.maxHeight);
      double maxHeight = max(400, constraints.maxHeight);
      double minWidth = max(400, constraints.maxWidth);
      double maxWidth = max(400, constraints.maxWidth);

      return Container(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: minHeight, maxHeight: maxHeight, minWidth: minWidth, maxWidth: maxWidth),
          child: AWatch(
            (context) => getLayout(context),
            dependencies: UISettings().allSignals,
            debugLabel: "HomeLayout",
          ),
        ),
      );
    });
  }

  // Widget getInsights() {
  //   var children = [const Flexible(flex: 6, child: BGLChart())];

  //   children.add(Flexible(
  //       flex: 4,
  //       child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
  //         Expanded(child: History()),
  //         Expanded(child: Stats()),
  //       ])));

  //   return Column(mainAxisAlignment: MainAxisAlignment.spaceAround, children: children);
  // }

  Widget getLayout(BuildContext context) {
    // We get super denormalized here so that if we change one thing
    // we wont have to test 20 things to make sure nothing broke
    final horizontal = MediaQuery.of(context).size.aspectRatio > 1.0;
    final isSnoozeShown = !AlarmSettings().disableAlarms;

    Widget snoozeBtn = const SizedBox.shrink();
    if (isSnoozeShown) {
      snoozeBtn = const SnoozeButton();
    }

    if (horizontal) {
      return Row(
        children: [
          Flexible(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Flexible(flex: 3, child: BGL()),
                Flexible(flex: 1, child: snoozeBtn),
              ],
            ),
          ),
          Flexible(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Flexible(flex: 3, child: BGLChart()),
                Flexible(
                  child: Row(
                    children: [
                      Flexible(child: History()),
                      Flexible(child: Stats()),
                    ],
                  ),
                )
              ],
            ),
          )
        ],
      );
    } else {
      return Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Flexible(flex: 6, child: BGL()),
          const Flexible(flex: 4, child: BGLChart()),
          Flexible(
            flex: 2,
            child: Row(
              children: [
                Flexible(child: History()),
                Flexible(child: Stats()),
              ],
            ),
          ),
          Flexible(child: snoozeBtn),
        ],
      );
    }
  }
}
