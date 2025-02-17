import 'package:carer/services/settings/alarm_settings.dart';
import 'package:carer/services/settings/ui_settings.dart';
import 'package:carer/services/themes_service.dart';
import 'package:carer/services/update_service.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/utils/logs.dart';
import 'package:carer/widgets/alarms/alarm_widget.dart';
import 'package:carer/widgets/bar/bar_top.dart';
import 'package:carer/widgets/bgl/bgl.dart';
import 'package:carer/widgets/insights/bgl_chart.dart';
import 'package:carer/widgets/insights/info.dart';
import 'package:carer/widgets/insights/treatments.dart';
import 'package:flutter/material.dart';

class DisplayPage extends StatelessWidget with ThemeMixin {
  const DisplayPage({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Scaffold(
          appBar: const BarTop(),
          body: RefreshIndicator(
            onRefresh: () async {
              alog("Forcing Update");
              UpdateService().forceUpdateAll();
              // just to see something is happening
              await Future.delayed(const Duration(seconds: 1));
            },
            displacement: 10,
            child: SingleChildScrollView(
              physics: const StickyRefreshPhysics(),
              padding: EdgeInsets.zero,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 40, maxHeight: constraints.maxHeight - 40),
                child: AWatch(
                  (context) {
                    return getLayout(context, UISettings().orientation);
                  },
                  dependencies: [AlarmSettings().disableAlarmsSignal, UISettings().orientationSignal],
                  debugLabel: "HomeLayout",
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget getLayout(BuildContext context, Orientation orientation) {
    if (orientation == Orientation.landscape) {
      return landscapeLayout();
    } else {
      return portraitLayout();
    }
  }

  Widget landscapeLayout() {
    return Row(
      children: [
        const Flexible(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(flex: 6, child: BGL()),
              AlarmWidget(flex: 2),
            ],
          ),
        ),
        Flexible(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Flexible(flex: 3, child: BGLChart()),
              Flexible(
                flex: 2,
                child: Row(
                  children: [
                    Flexible(child: Treatments()),
                    Flexible(child: InfoWidget()),
                  ],
                ),
              )
            ],
          ),
        ),
      ],
    );
  }

  Widget portraitLayout() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Expanded(flex: 4, child: BGL()),
        const AlarmWidget(flex: 2),
        const Flexible(flex: 4, child: BGLChart()),
        Flexible(
          flex: 2,
          child: Row(
            children: [
              Flexible(child: Treatments()),
              Flexible(child: InfoWidget()),
            ],
          ),
        ),
      ],
    );
  }
}

class StickyRefreshPhysics extends ScrollPhysics {
  const StickyRefreshPhysics({super.parent});

  @override
  StickyRefreshPhysics applyTo(ScrollPhysics? ancestor) {
    return StickyRefreshPhysics(parent: buildParent(ancestor));
  }

  // Always draggable
  @override
  bool shouldAcceptUserOffset(ScrollMetrics position) => true;

  // Increase the distance needed to pull down to start drag, so it doesn't interfere with other interactions like chart
  @override
  double get dragStartDistanceMotionThreshold => 50;
}
