import 'package:carer/change_notifiers/settings/ui_settings.dart';
import 'package:carer/change_notifiers/settings_cn.dart';
import 'package:carer/change_notifiers/update_cn.dart';
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
    //UITheme uiTheme = settings.uiSettings.uiTheme; TODO

    final aspectRatio = MediaQuery.of(context).size.aspectRatio;
    final isHorizontal = aspectRatio > 1.0;

    return Consumer2<SettingsCN, UpdateCN>(
        builder: (context, settings, summaryCn, child) {
      UILayout layout = settings.uiSettings.uiLayoutVertical;
      if (isHorizontal) {
        layout = settings.uiSettings.uiLayoutHorizontal;
      }

      var bgl = const Flexible(flex: 4, child: BGL());

      Widget mainLine = Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround, children: [bgl]);

      if (isHorizontal) {
        switch (layout) {
          case UILayout.showBGLChartHistoryStats:
            mainLine = Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [bgl, Flexible(flex: 3, child: getInsights())]);
            break;
          default:
            mainLine = Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [bgl]);
        }
      } else {
        switch (layout) {
          case UILayout.showBGLChartHistoryStats:
            mainLine = Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [bgl, Flexible(flex: 5, child: getInsights())]);
            break;
          default:
            mainLine = Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [bgl]);
        }
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

  Widget getInsights() {
    var children = [const Flexible(child: BGLChart())];

    children.add(const Flexible(
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
      Expanded(child: History()),
      Expanded(child: Stats()),
    ])));

    return Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround, children: children);
  }
}
