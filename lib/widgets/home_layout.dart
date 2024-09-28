import 'package:carer/services/settings/alarm_settings.dart';
import 'package:carer/services/settings/ui_settings.dart';
import 'package:carer/services/themes_service.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/widgets/alarms/snoozebutton.dart';
import 'package:carer/widgets/bgl/bgl.dart';
import 'package:carer/widgets/current_time.dart';
import 'package:carer/widgets/insights/bgl_chart.dart';
import 'package:carer/widgets/insights/history.dart';
import 'package:carer/widgets/insights/stats.dart';
import 'package:flutter/material.dart';

// Enumeration of all layout types
// I dont want to do anything funky here, easier to enumnerate and build individually with limited blast radias for errors
enum LayoutTypes {
  horizontalBGL,
  horizontalBGLWithSnooze,

  horizonalBGLWithInsights,
  horizonalBGLWithInsightsAndSnooze,

  horizontalMinimal,
  horizontalMinimalWithSnooze,

  verticalBGL,
  verticalBGLWithSnooze,

  verticalBGLWithInsights,
  verticalBGLWithInsightsAndSnooze,

  verticalMinimal,
  verticalMinimalWithSnooze,
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
          const Positioned(
            top: 0, // Adjust these values as needed
            left: 5,
            child: FittedBox(child: CurrentTimeWidget()),
          ),
        ],
      ),
    );
  }

  // All layout selection logic here, try figure out what needs to be seen outside of the rendering
  LayoutTypes layoutType(BuildContext context) {
    var layout = UISettings().layout;

    final horizontal = MediaQuery.of(context).size.aspectRatio > 1.0;
    final isSnoozeShown = !AlarmSettings().disableAlarms;

    switch ((horizontal, isSnoozeShown, layout)) {
      case (false, false, UILayout.showBGL):
        return LayoutTypes.verticalBGL;
      case (false, true, UILayout.showBGL):
        return LayoutTypes.verticalBGLWithSnooze;
      case (true, false, UILayout.showBGL):
        return LayoutTypes.horizontalBGL;
      case (true, true, UILayout.showBGL):
        return LayoutTypes.horizontalBGLWithSnooze;

      case (false, false, UILayout.showBGLChartHistoryStats):
        return LayoutTypes.verticalBGLWithInsights;
      case (false, true, UILayout.showBGLChartHistoryStats):
        return LayoutTypes.verticalBGLWithInsightsAndSnooze;
      case (true, false, UILayout.showBGLChartHistoryStats):
        return LayoutTypes.horizonalBGLWithInsights;
      case (true, true, UILayout.showBGLChartHistoryStats):
        return LayoutTypes.horizonalBGLWithInsightsAndSnooze;

      case (false, false, UILayout.showMinimal):
        return LayoutTypes.verticalMinimal;
      case (false, true, UILayout.showMinimal):
        return LayoutTypes.verticalMinimalWithSnooze;
      case (true, false, UILayout.showMinimal):
        return LayoutTypes.horizontalMinimal;
      case (true, true, UILayout.showMinimal):
        return LayoutTypes.horizontalMinimalWithSnooze;
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
      case LayoutTypes.horizontalBGL:
        return flexListCol([4], [const BGL()]);
      case LayoutTypes.horizontalBGLWithSnooze:
        return flexListCol([4, 1], [const BGL(), const SnoozeButton()]);
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
      case LayoutTypes.verticalBGL:
        return flexListRow([4], [const BGL()]);
      case LayoutTypes.verticalBGLWithSnooze:
        return flexListCol([-1, 4, -1, 1], [const SizedBox.shrink(), const BGL(), const SizedBox.shrink(), const SnoozeButton()]);
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
      case LayoutTypes.horizontalMinimal:
        return flexListRow([
          5,
          5
        ], [
          flexListCol([4], [const BGL()]),
          getMinimalInsights(),
        ]);
      case LayoutTypes.horizontalMinimalWithSnooze:
        return flexListRow([
          5,
          5
        ], [
          flexListCol([20, 5], [const BGL(), const SnoozeButton()]),
          getMinimalInsights(),
        ]);
      case LayoutTypes.verticalMinimal:
        return flexListCol([
          5,
          5
        ], [
          flexListRow([4], [const BGL()]),
          getMinimalInsights()
        ]);
      case LayoutTypes.verticalMinimalWithSnooze:
        return flexListCol([
          10,
          12,
          -1,
          3,
        ], [
          flexListRow([4], [const BGL()]),
          getMinimalInsights(),
          const SizedBox.shrink(),
          const SnoozeButton(),
        ]);
    }
  }
}
