import 'package:animations/animations.dart';
import 'package:carer/services/settings/alarm_settings.dart';
import 'package:carer/services/themes_service.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/widgets/common/dialogs.dart';
import 'package:carer/widgets/settings/alarm_alerts_settings.dart';
import 'package:carer/widgets/settings/alarms_settings.dart';
import 'package:carer/widgets/settings/snooze_alarms_settings.dart';
import 'package:carer/widgets/settings/t1d_settings.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_settings_ui/flutter_settings_ui.dart';

enum AlarmSettingsPages { alerts, alarms, settings }

class AlarmsSettingsPage extends StatefulWidget {
  const AlarmsSettingsPage({super.key});

  @override
  State<AlarmsSettingsPage> createState() => _AlarmsSettingsPageState();
}

class _AlarmsSettingsPageState extends State<AlarmsSettingsPage> with ThemeMixin {
  var _selectedSegment = AlarmSettingsPages.alarms;

  @override
  Widget build(BuildContext context) {
    return AWatch(
      (context) {
        var alarmsPage = SettingsList(
          key: const Key("AlarmsSettingsPageAlarms"),
          sections: [
            SettingsSection(tiles: [
              disableAlarms(context),
            ]),
            const AlarmsSettingsWidget(),
          ],
        );

        var alertsPage = SettingsList(
          key: const Key("AlarmsSettingsPageAlerts"),
          sections: [
            SettingsSection(tiles: [
              disableAlarms(context),
            ]),
            const AlarmsAlertSettingsWidget(),
          ],
        );

        var settingsPage = SettingsList(
          key: const Key("AlarmsSettingsPageSettings"),
          sections: [
            SettingsSection(tiles: [
              disableAlarms(context),
            ]),
            TargetSettingsWidget(),
            const SnoozeAlarmsSettings(),
          ],
        );

        var child = alarmsPage;
        switch (_selectedSegment) {
          case AlarmSettingsPages.alarms:
            child = alarmsPage;
            break;
          case AlarmSettingsPages.alerts:
            child = alertsPage;
            break;
          case AlarmSettingsPages.settings:
            child = settingsPage;
            break;
        }
        // AlarmsPage

        return Scaffold(
          appBar: AppBar(title: const Text('Alarms')),
          backgroundColor: Colors.black,
          body: CupertinoPageScaffold(
            navigationBar: CupertinoNavigationBar(
              automaticallyImplyLeading: false,
              automaticallyImplyMiddle: false,
              automaticBackgroundVisibility: false,
              enableBackgroundFilterBlur: false,
              backgroundColor: Colors.black,
              // This Cupertino segmented control has the enum "Sky" as the type.
              middle: CupertinoSlidingSegmentedControl<AlarmSettingsPages>(
                // This represents the currently selected segmented control.
                groupValue: _selectedSegment,
                // Callback that sets the selected segmented control.
                onValueChanged: (AlarmSettingsPages? value) {
                  if (value != null) {
                    setState(() {
                      _selectedSegment = value;
                    });
                  }
                },
                children: <AlarmSettingsPages, Widget>{
                  AlarmSettingsPages.alarms: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text('Alarms', style: TextStyle(color: onBackgroundColor(context))),
                  ),
                  AlarmSettingsPages.alerts: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text('Alerting', style: TextStyle(color: onBackgroundColor(context))),
                  ),
                  AlarmSettingsPages.settings: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text('Settings', style: TextStyle(color: onBackgroundColor(context))),
                  ),
                },
              ),
            ),
            child: PageTransitionSwitcher(
              duration: const Duration(milliseconds: 300),
              child: child,
              transitionBuilder: (child, primaryAnimation, secondaryAnimation) {
                return SharedAxisTransition(
                  animation: primaryAnimation,
                  secondaryAnimation: secondaryAnimation,
                  transitionType: SharedAxisTransitionType.horizontal,
                  fillColor: Colors.black,
                  child: child,
                );
              },
            ),
          ),
        );
      },
      debugLabel: "AlarmsSettingsPage",
      dependencies: [AlarmSettings().disableAlarmsSignal],
    );
  }

  SettingsTile disableAlarms(BuildContext context) {
    return SettingsTile.switchTile(
      title: const Text("Disable Alarms"),
      descriptionInlineIos: true,
      description: const Text(
        "Turn off all alarms",
      ),
      initialValue: AlarmSettings().disableAlarms,
      onToggle: (bool disable) async {
        if (!disable) {
          AlarmSettings().disableAlarms = false;
          return;
        }
        // show the dialog
        bool? areYouSure = await Dialogs.areYouSureDialog(context, "Disable Alarms", "Disable all alarms (not recommended)?", "Disable");
        if (areYouSure == true) {
          AlarmSettings().disableAlarms = true;
        }
      },
    );
  }
}
