import 'package:carer/services/settings/ui_settings.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/widgets/bgl/bgl.dart';
import 'package:carer/widgets/current_time.dart';
import 'package:carer/widgets/insights/bgl_chart.dart';
import 'package:carer/widgets/insights/history.dart';
import 'package:carer/widgets/insights/stats.dart';
import 'package:flutter/material.dart';

class HomeLayout extends StatelessWidget {
  const HomeLayout({super.key});

  @override
  Widget build(BuildContext context) {
    // This needs hardcoding because the scrollable outer widget

    return LayoutBuilder(
      builder: (context, constraints) => Stack(
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight, maxHeight: constraints.maxHeight),
            child: AWatch((context) => getLayout(context, UISettings().uiLayoutVertical, UISettings().uiLayoutHorizontal)),
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
}

Widget getLayout(BuildContext context, UILayout uiLayoutVertical, uiLayoutHorizontal) {
  final aspectRatio = MediaQuery.of(context).size.aspectRatio;
  final isHorizontal = aspectRatio > 1.0;

  UILayout layout = uiLayoutVertical;
  if (isHorizontal) {
    layout = uiLayoutHorizontal;
  }

  var bgl = const Flexible(flex: 4, child: BGL());

  Widget mainLine = Column(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [bgl]);

  if (isHorizontal) {
    switch (layout) {
      case UILayout.showBGLChartHistoryStats:
        mainLine = Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [bgl, Flexible(flex: 3, child: getInsights())]);
        break;
      default:
        mainLine = Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [bgl]);
    }
  } else {
    switch (layout) {
      case UILayout.showBGLChartHistoryStats:
        mainLine = Column(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [bgl, Flexible(flex: 5, child: getInsights())]);
        break;
      default:
        mainLine = Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [bgl]);
    }
  }
  return mainLine;
}

Widget getInsights() {
  var children = [const Flexible(child: BGLChart())];

  children.add(const Flexible(
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
    Expanded(child: History()),
    Expanded(child: Stats()),
  ])));

  return Column(mainAxisAlignment: MainAxisAlignment.spaceAround, children: children);
}
