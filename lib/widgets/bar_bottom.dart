import 'package:carer/services/settings/alarm_alert_settings.dart';
import 'package:carer/services/themes_service.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/widgets/pages/settingspage.dart';
import 'package:flutter/material.dart';

class BarBottom extends StatelessWidget with ThemeMixin {
  const BarBottom({super.key});

  @override
  Widget build(BuildContext context) {
    return AWatch(
      (context) {
        List<Widget> tiles = [
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
      debugLabel: "BarBottom",
      dependencies: [ThemeService().themeSignal, AlarmAlertSettings().snoozeUntilSignal],
    );
  }

  Widget getSettingsButton(BuildContext context) {
    return IconButton(
      color: Colors.white,
      highlightColor: Colors.white,
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all<Color>(onSurfaceColor(context)),
      ),
      padding: EdgeInsets.zero,
      icon: Icon(
        Icons.settings,
        color: tertiaryColor(context),
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
