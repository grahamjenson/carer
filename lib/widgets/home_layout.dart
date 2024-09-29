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

// Enumeration of all layout types
// I dont want to do anything funky here, easier to enumnerate and build individually with limited blast radias for errors
enum LayoutTypes {
  horizonalBGLWithInsights,
  horizonalBGLWithInsightsAndSnooze,

  verticalBGLWithInsights,
  verticalBGLWithInsightsAndSnooze,
}

class HomeLayout extends StatelessWidget with ThemeMixin {
  HomeLayout({super.key});

  @override
  Widget build(BuildContext context) {
    // This needs hardcoding because the scrollable outer widget

    return LayoutBuilder(
      builder: (context, constraints) => Stack(
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight, maxHeight: constraints.maxHeight),
            child: AWatch(
              (context) => getLayout(layoutType(context)),
              dependencies: UISettings().allSignals,
              debugLabel: "HomeLayout",
            ),
          ),
        ],
      ),
    );
  }

  // All layout selection logic here, try figure out what needs to be seen outside of the rendering
  LayoutTypes layoutType(BuildContext context) {
    final horizontal = MediaQuery.of(context).size.aspectRatio > 1.0;
    final isSnoozeShown = !AlarmSettings().disableAlarms;

    switch ((horizontal, isSnoozeShown)) {
      case (false, false):
        return LayoutTypes.verticalBGLWithInsights;
      case (false, true):
        return LayoutTypes.verticalBGLWithInsightsAndSnooze;
      case (true, false):
        return LayoutTypes.horizonalBGLWithInsights;
      case (true, true):
        return LayoutTypes.horizonalBGLWithInsightsAndSnooze;
    }
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
    return Column(mainAxisAlignment: MainAxisAlignment.spaceAround, children: flexList(flexes, widgets));
  }

  Row flexListRow(List<int> flexes, List<Widget> widgets) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: flexList(flexes, widgets));
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

  Widget getMinimalInsights() {
    // TODO: This should be different widgets that are much cleaner
    return History();
  }

  Widget getLayout(LayoutTypes layout) {
    // We get super denormalized here so that if we change one thing
    // we wont have to test 20 things to make sure nothing broke

    switch (layout) {
      case LayoutTypes.horizonalBGLWithInsights:
        return flexListRow([
          5,
          5
        ], [
          flexListCol([4], [const BGL()]),
          getInsights()
        ]);
      case LayoutTypes.horizonalBGLWithInsightsAndSnooze:
        return flexListRow([
          5,
          5
        ], [
          flexListCol([20, 5], [const BGL(), const SnoozeButton()]),
          getInsights()
        ]);

      case LayoutTypes.verticalBGLWithInsights:
        return flexListCol([
          5,
          5
        ], [
          flexListRow([4], [const BGL()]),
          getInsights()
        ]);
      case LayoutTypes.verticalBGLWithInsightsAndSnooze:
        return flexListCol([
          10,
          12,
          -1,
          3,
        ], [
          flexListRow([4], [const BGL()]),
          getInsights(),
          const SizedBox.shrink(),
          const SnoozeButton(),
        ]);
    }
  }
}
