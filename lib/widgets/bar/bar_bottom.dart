import 'package:carer/services/settings/alarm_alert_settings.dart';
import 'package:carer/services/settings/alarm_settings.dart';
import 'package:carer/services/themes_service.dart';
import 'package:carer/services/ui/icons.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/widgets/alarms/snooze_bar_button.dart';
import 'package:carer/widgets/pages/alarm_settings_page.dart';
import 'package:carer/widgets/pages/care_page.dart';
import 'package:carer/widgets/pages/info_settings_page.dart';
import 'package:carer/widgets/pages/settingspage.dart';
import 'package:flutter/material.dart';

class BarBottom extends StatelessWidget with ThemeMixin {
  final bool vertical;
  const BarBottom({super.key, this.vertical = false});

  @override
  Widget build(BuildContext context) {
    return AWatch(
      (context) {
        var children = [
          createButton(context, "Care", CarerIcons.BAR_CARE, const CarePage()),
          createButton(context, "Info", CarerIcons.BAR_INFO, const InfoSettingsPage()),
          createButton(context, "Alarms", CarerIcons.BAR_ALARMS, const AlarmsSettingsPage()),
          createButton(context, "Settings", CarerIcons.BAR_SETTINGS, const SettingsPage()),
        ];

        NotchedShape? notchShape;
        if (!AlarmSettings().disableAlarms) {
          // Add gap for floating button
          children.insert(2, const Flexible(flex: 5, child: SnoozeBarButton()));

          notchShape = const AutomaticNotchedShape(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(15),
              ),
            ),
            RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
          );
        }
        return BottomAppBar(
            color: backgroundColorShade(context),
            shape: notchShape,
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: children));
      },
      debugLabel: "BarBottom",
      dependencies: [ThemeService().themeSignal, AlarmAlertSettings().snoozeUntilSignal, AlarmSettings().disableAlarmsSignal],
    );
  }

  Widget createButton(BuildContext context, String name, IconData id, Widget navigateTo) {
    return Flexible(
      flex: 1,
      child: IconButtonWithText(
        icon: id,
        label: name,
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

class IconButtonWithText extends StatelessWidget with ThemeMixin {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const IconButtonWithText({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.all<Color>(onBackgroundColor(context)),
        backgroundColor: WidgetStateProperty.all<Color>(backgroundColorShade(context)),
        padding: WidgetStateProperty.all<EdgeInsetsGeometry>(const EdgeInsets.all(0)),
        shape: WidgetStateProperty.all<RoundedRectangleBorder>(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
        textStyle: WidgetStateProperty.all<TextStyle>(const TextStyle(fontSize: 12.0)),
      ),
      onPressed: onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 28.0,
            weight: 0.01,
          ),
          const SizedBox(height: 4.0),
          Text(label),
        ],
      ),
    );
  }
}
