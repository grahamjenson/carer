import 'package:carer/services/settings/alarm_settings.dart';
import 'package:carer/services/settings/ui_settings.dart';
import 'package:carer/services/themes_service.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/widgets/alarms/sleepbutton.dart';
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
  horizontalBGLWithSleep,
  horizonalBGLWithInsights,
  horizonalBGLWithInsightsAndSleep,

  verticalBGL,
  verticalBGLWithSleep,
  verticalBGLWithInsights,
  verticalBGLWithInsightsAndSleep,
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
              dependencies: UISettings().themeLayoutSignals,
            ),
          ),
          const Positioned(
            top: 10, // Adjust these values as needed
            left: 10,
            child: FittedBox(child: CurrentTimeWidget()),
          ),
        ],
      ),
    );
  }

  // All layout selection logic here, try figure out what needs to be seen outside of the rendering
  LayoutTypes layoutType(BuildContext context) {
    UIThemeLayout tl = ThemeService().getCurrentThemeLayout();

    var horizontalLayout = tl.horizonalLayout;
    var verticalLayout = tl.verticalLayout;

    final isHorizontal = MediaQuery.of(context).size.aspectRatio > 1.0;
    final isSleepShown = !AlarmSettings().disableAlarms;
    var layout = isHorizontal ? horizontalLayout : verticalLayout;

    switch ((isHorizontal, isSleepShown, layout)) {
      case (false, false, UILayout.showBGL):
        return LayoutTypes.verticalBGL;
      case (false, true, UILayout.showBGL):
        return LayoutTypes.verticalBGLWithSleep;
      case (false, false, UILayout.showBGLChartHistoryStats):
        return LayoutTypes.verticalBGLWithInsights;
      case (false, true, UILayout.showBGLChartHistoryStats):
        return LayoutTypes.verticalBGLWithInsightsAndSleep;
      case (true, false, UILayout.showBGL):
        return LayoutTypes.horizontalBGL;
      case (true, true, UILayout.showBGL):
        return LayoutTypes.horizontalBGLWithSleep;
      case (true, false, UILayout.showBGLChartHistoryStats):
        return LayoutTypes.horizonalBGLWithInsights;
      case (true, true, UILayout.showBGLChartHistoryStats):
        return LayoutTypes.horizonalBGLWithInsightsAndSleep;
      default:
        throw UnimplementedError('Layout not implemented');
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
    var children = [const Flexible(child: BGLChart())];

    children.add(Flexible(
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
      Expanded(child: History()),
      Expanded(child: Stats()),
    ])));

    return Column(mainAxisAlignment: MainAxisAlignment.spaceAround, children: children);
  }

  Widget getLayout(LayoutTypes layout) {
    switch (layout) {
      case LayoutTypes.horizontalBGL:
        return flexListCol([4], [const BGL()]);
      case LayoutTypes.horizontalBGLWithSleep:
        return flexListCol([4, 1], [const BGL(), const SleepButton()]);
      case LayoutTypes.horizonalBGLWithInsights:
        return flexListRow([
          5,
          5
        ], [
          flexListCol([4], [const BGL()]),
          getInsights()
        ]);
      case LayoutTypes.horizonalBGLWithInsightsAndSleep:
        return flexListRow([
          5,
          5
        ], [
          flexListCol([20, 5], [const BGL(), const SleepButton()]),
          getInsights()
        ]);
      case LayoutTypes.verticalBGL:
        return flexListRow([4], [const BGL()]);
      case LayoutTypes.verticalBGLWithSleep:
        return flexListCol([-1, 4, -1, 1], [const SizedBox.shrink(), const BGL(), const SizedBox.shrink(), const SleepButton()]);
      case LayoutTypes.verticalBGLWithInsights:
        return flexListCol([
          5,
          5
        ], [
          flexListRow([4], [const BGL()]),
          getInsights()
        ]);
      case LayoutTypes.verticalBGLWithInsightsAndSleep:
        return flexListCol([
          10,
          12,
          -1,
          3,
        ], [
          flexListRow([4], [const BGL()]),
          getInsights(),
          const SizedBox.shrink(),
          const SleepButton(),
        ]);
      default:
        throw UnimplementedError('Layout not implemented');
    }
  }
}
