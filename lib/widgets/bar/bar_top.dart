import 'package:carer/services/settings/alarm_alert_settings.dart';
import 'package:carer/services/settings/ui_settings.dart';
import 'package:carer/services/themes_service.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/widgets/bar/alarms_bar.dart';
import 'package:carer/widgets/bar/status_bar.dart';
import 'package:carer/widgets/current_time.dart';
import 'package:flutter/material.dart';

class BarTop extends StatelessWidget with ThemeMixin implements PreferredSizeWidget {
  const BarTop({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(40);

  @override
  Widget build(BuildContext context) {
    return AWatch(
      (context) {
        var fixedWidth = 100.0;
        List<Widget> tiles = [
          SizedBox(
            width: fixedWidth,
            child: const CurrentTimeWidget(),
          ),
          SizedBox(
            width: fixedWidth,
            child: const StatusesBar(),
          ),
          SizedBox(
            width: fixedWidth,
            child: AlarmsBarIcons(),
          ),
        ];

        return BottomAppBar(
          color: backgroundColorShade(context),
          padding: const EdgeInsets.only(left: 8, right: 8),
          height: 40,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: tiles,
          ),
        );
      },
      debugLabel: "BarTop",
      dependencies: [ThemeService().themeSignal, AlarmAlertSettings().snoozeUntilSignal, UISettings().orientationSignal],
    );
  }
}
