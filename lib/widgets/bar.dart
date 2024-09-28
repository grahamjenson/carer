import 'package:carer/services/settings/alarm_alert_settings.dart';
import 'package:carer/services/themes_service.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/widgets/alarms/alarms_bar.dart';
import 'package:carer/widgets/alarms/status_bar.dart';
import 'package:carer/widgets/pages/settingspage.dart';
import 'package:flutter/material.dart';

class Bar extends StatelessWidget with ThemeMixin {
  const Bar({super.key});

  @override
  Widget build(BuildContext context) {
    return AWatch(
      (context) {
        List<Widget> tiles = [
          const StatusesBar(),
          AlarmsBarIcons(),
          const Expanded(
            child: SizedBox.shrink(),
          ),
          getSettingsButton(context),
        ];

        return BottomAppBar(
          color: Colors.transparent,
          padding: const EdgeInsets.only(left: 8, right: 8),
          height: 40,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: tiles,
          ),
        );
      },
      debugLabel: "Bar",
      dependencies: [ThemeService().themeSignal, AlarmAlertSettings().snoozeUntilSignal],
    );
  }

  Widget getSettingsButton(BuildContext context) {
    return IconButton(
      padding: EdgeInsets.zero,
      icon: Icon(
        Icons.settings,
        color: primaryColor(context),
      ),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SettingsPage()),
        );
      },
    );
  }
}
