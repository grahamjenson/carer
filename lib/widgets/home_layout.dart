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
    return AWatch(
      (context) {
        return getLayout(context, UISettings().orientation);
      },
      dependencies: [AlarmSettings().disableAlarmsSignal, UISettings().orientationSignal],
      debugLabel: "HomeLayout",
    );
  }

  Widget getLayout(BuildContext context, Orientation orientation) {
    final isSnoozeHidden = AlarmSettings().disableAlarms;

    var snoozeFlex = 1;
    if (isSnoozeHidden) {
      snoozeFlex = 0;
    }

    if (orientation == Orientation.landscape) {
      return Row(
        children: [
          Flexible(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  flex: 6,
                  child: SizedBox.expand(child: BGL()),
                ),
                Flexible(flex: 2 * snoozeFlex, child: const SnoozeButton()),
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
          const Expanded(flex: 4, child: SizedBox.expand(child: BGL())),
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
          Flexible(flex: 2 * snoozeFlex, child: const SnoozeButton()),
        ],
      );
    }
  }
}
