import 'package:carer/services/settings/alarm_settings.dart';
import 'package:carer/services/settings/ui_settings.dart';
import 'package:carer/services/themes_service.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/widgets/alarms/alarm_widget.dart';
import 'package:carer/widgets/bgl/bgl.dart';
import 'package:carer/widgets/insights/bgl_chart.dart';
import 'package:carer/widgets/insights/info.dart';
import 'package:carer/widgets/insights/treatments.dart';
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
              AlarmWidget(flex: 2),
              Expanded(flex: 6, child: BGL()),
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
        const AlarmWidget(flex: 2),
        const Expanded(flex: 4, child: BGL()),
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
