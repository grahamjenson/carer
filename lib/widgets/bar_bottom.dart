import 'package:carer/services/settings/alarm_alert_settings.dart';
import 'package:carer/services/themes_service.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/widgets/bar/care_btn.dart';
import 'package:carer/widgets/bar/settings_btn.dart';
import 'package:flutter/material.dart';
import 'package:unicons/unicons.dart';

class BarBottom extends StatelessWidget with ThemeMixin {
  const BarBottom({super.key});

  @override
  Widget build(BuildContext context) {
    return AWatch(
      (context) {
        List<Widget> tiles = [
          const CareBtn(),
          IconButton(
            icon: const Icon(UniconsLine.list_ul),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(UniconsLine.bell),
            onPressed: () {},
          ),
          const SettingsBtn(),
        ];

        return BottomAppBar(
          color: backgroundColorShade(context),
          notchMargin: 5.0,
          clipBehavior: Clip.antiAlias,
          height: kBottomNavigationBarHeight,
          shape: const CircularNotchedRectangle(),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: tiles,
          ),
        );
      },
      debugLabel: "BarBottom",
      dependencies: [ThemeService().themeSignal, AlarmAlertSettings().snoozeUntilSignal],
    );
  }
}
