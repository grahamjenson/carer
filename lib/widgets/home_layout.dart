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
      double minHeight = max(0, constraints.maxHeight);
      double maxHeight = max(100, constraints.maxHeight);
      return Stack(
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(minHeight: minHeight, maxHeight: maxHeight),
            child: AWatch(
              (context) => getLayout(context),
              dependencies: UISettings().allSignals,
              debugLabel: "HomeLayout",
            ),
          ),
        ],
      );
    });
  }

  List<Flexible> flexList(List<int> flexes, List<Widget> widgets) {
    assert(flexes.length == widgets.length);
    var list = <Flexible>[];
    for (var i = 0; i < flexes.length; i++) {
      var child = widgets[i];
      if (flexes[i] == -1) {
        list.add(Expanded(child: child));
        continue;
      }
      list.add(Flexible(flex: flexes[i], child: child));
    }
    return list;
  }

  Column flexListCol(List<int> flexes, List<Widget> widgets) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: flexList(flexes, widgets),
    );
  }

  Row flexListRow(List<int> flexes, List<Widget> widgets) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: flexList(flexes, widgets),
    );
  }

  Widget getInsights() {
    var children = [const Flexible(flex: 6, child: BGLChart())];

    children.add(Flexible(
        flex: 4,
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          Expanded(child: History()),
          Expanded(child: Stats()),
        ])));

    return Column(mainAxisAlignment: MainAxisAlignment.spaceAround, children: children);
  }

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
      return flexListRow([
        5,
        5
      ], [
        flexListCol([20, 5], [const BGL(), snoozeBtn]),
        getInsights()
      ]);
    } else {
      return flexListCol([
        10,
        12,
        -1,
        3,
      ], [
        flexListRow([4], [const BGL()]),
        getInsights(),
        const SizedBox.shrink(),
        snoozeBtn,
      ]);
    }
  }
}
