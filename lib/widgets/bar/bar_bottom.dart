import 'package:carer/services/settings/alarm_alert_settings.dart';
import 'package:carer/services/themes_service.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/widgets/pages/care_page.dart';
import 'package:carer/widgets/pages/settingspage.dart';
import 'package:flutter/material.dart';

class BarBottom extends StatelessWidget with ThemeMixin {
  final bool vertical;
  const BarBottom({super.key, this.vertical = false});

  @override
  Widget build(BuildContext context) {
    return AWatch(
      (context) {
        return BottomAppBar(
            color: backgroundColorShade(context),
            shape: const AutomaticNotchedShape(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(15),
                ),
              ),
              RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
            ),
            notchMargin: 5.0,
            clipBehavior: Clip.antiAlias,
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                createButton(context, "Care", Icons.back_hand_outlined, const CarePage()),
                createButton(context, "Alarms", Icons.settings_outlined, const SettingsPage()),
                const Spacer(),
                createButton(context, "Stats", Icons.settings_outlined, const SettingsPage()),
                createButton(context, "Settings", Icons.settings_outlined, const SettingsPage()),
              ],
            ));
      },
      debugLabel: "BarBottom",
      dependencies: [ThemeService().themeSignal, AlarmAlertSettings().snoozeUntilSignal],
    );
  }

  Widget createButton(BuildContext context, String name, IconData id, Widget navigateTo) {
    return Flexible(
      flex: 1,
      child: ElevatedButton(
        child: Column(children: [
          Icon(id, size: 16),
          Text(name, style: labelSmall(context)),
        ]),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => navigateTo),
          );
        },
      ),
    );
  }
}
