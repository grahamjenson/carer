import 'package:carer/services/settings/alarm_alert_settings.dart';
import 'package:carer/services/themes_service.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/widgets/alarms/alarms_bar.dart';
import 'package:carer/widgets/alarms/status_bar.dart';
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
        List<Widget> tiles = [
          const CurrentTimeWidget(),
          const Expanded(
            child: SizedBox.shrink(),
          ),
          const StatusesBar(),
          AlarmsBarIcons(),
        ];

        return BottomAppBar(
          color: const Color.fromRGBO(0, 0, 0, 0),
          padding: const EdgeInsets.only(left: 8, right: 8),
          height: 40,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: tiles,
          ),
        );
      },
      debugLabel: "BarTop",
      dependencies: [ThemeService().themeSignal, AlarmAlertSettings().snoozeUntilSignal],
    );
  }
}
