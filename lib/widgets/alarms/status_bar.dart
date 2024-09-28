import 'package:carer/models/properties_data.dart';
import 'package:carer/services/platform_info_service.dart';
import 'package:carer/services/settings/alarm_alert_settings.dart';
import 'package:carer/services/settings/device_settings.dart';
import 'package:carer/services/themes_service.dart';
import 'package:carer/services/timer_service.dart';
import 'package:carer/utils/futures.dart';
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:unicons/unicons.dart';

class StatusesBar extends StatelessWidget with ThemeMixin {
  const StatusesBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AWatch(
      (context) {
        List<Widget?> rowsMaybe = [
          getIsSilentOnIcon(context),
          sensorChangeDay(context),
          cannulaChangeDay(context),
          getIsPluggedInIcon(context),
          getPhoneLowPower(context),
        ];
        List<Widget> rows = rowsMaybe.whereType<Widget>().toList();

        if (rows.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.all(4), // Add padding inside the border
          decoration: BoxDecoration(
            border: Border.all(
              color: tertiaryColor(context), // Color of the border
              width: 1, // Width of the border
            ),
            borderRadius: BorderRadius.circular(5), // Optional: if you want rounded corners
          ),
          child: Row(
            children: rows,
          ),
        );
      },
      dependencies: [
        ThemeService().themeSignal,
        AlarmAlertSettings().sleepUntilSignal,
        TimerService().fiveSecondSignal,
        PlatformInfoService().ringerMode,
        PlatformInfoService().batteryMode,
      ],
      debugLabel: "StatusesBar",
    );
  }

  Widget? getIsSilentOnIcon(BuildContext context) {
    var ringer = PlatformInfoService().ringerMode.value;
    if (ringer == RingerMode.silent || ringer == RingerMode.vibrate) {
      return Tooltip(
        message: "Silent Mode",
        triggerMode: TooltipTriggerMode.tap,
        child: Icon(
          UniconsLine.bell_slash,
          color: tertiaryColor(context),
        ),
      );
    }
    return null;
  }

  Widget? sensorChangeDay(BuildContext context) {
    var sage = PropertiesData().sage;
    var sageExpiry = sage.add(DeviceSettings().sensorDuration);
    var hours = sageExpiry.difference(clock.now()).inHours;

    var hoursStr = "in ${hours}h";
    if (hours < 1) {
      hoursStr = "NOW";
    }

    if (hours < 24) {
      return Tooltip(
        message: "Sensor Change $hoursStr",
        triggerMode: TooltipTriggerMode.tap,
        child: Icon(
          UniconsLine.processor,
          color: tertiaryColor(context),
        ),
      );
    }
    return null;
  }

  Widget? cannulaChangeDay(BuildContext context) {
    var cage = PropertiesData().cage;
    var cageExpiry = cage.add(DeviceSettings().cannulaDuration);
    var hours = cageExpiry.difference(clock.now()).inHours;

    var hoursStr = "in ${hours}h";
    if (hours < 1) {
      hoursStr = "NOW";
    }

    if (hours < 24) {
      return Tooltip(
        message: "Cannula Change $hoursStr",
        triggerMode: TooltipTriggerMode.tap,
        child: Icon(
          UniconsLine.mobile_android,
          color: tertiaryColor(context),
        ),
      );
    }
    return null;
  }

  Widget? getIsPluggedInIcon(BuildContext context) {
    var thisPhonesCharging = PlatformInfoService().thisPhoneIsCharging();
    var t1dPhonesCharging = PropertiesData().t1dPhoneIsCharging();

    List<String> tooltip = [];

    if (!thisPhonesCharging) {
      tooltip.add("This Phone Not Charging");
    }
    if (!t1dPhonesCharging) {
      tooltip.add("T1D Phone Not Charging");
    }

    if (tooltip.isNotEmpty) {
      return Tooltip(
        message: tooltip.join(", "),
        triggerMode: TooltipTriggerMode.tap,
        child: Icon(
          UniconsLine.bolt_slash,
          color: tertiaryColor(context),
        ),
      );
    }
    return null;
  }

  Widget? getPhoneLowPower(BuildContext context) {
    var thisPhonesCharging = PlatformInfoService().thisPhoneIsCharging();
    var t1dPhonesCharging = PropertiesData().t1dPhoneIsCharging();

    var thisPhonesBattery = PlatformInfoService().thisPhonesBatteryLevel();
    var t1dPhonesBatteryLevel = PropertiesData().t1dPhonesBatteryLevel();

    List<String> tooltip = [];

    if (!thisPhonesCharging && thisPhonesBattery < 30) {
      tooltip.add("This Phones Battery < 30%($thisPhonesBattery%)");
    }
    if (!t1dPhonesCharging && t1dPhonesBatteryLevel < 30) {
      tooltip.add("T1D Phones Battery < 30%($t1dPhonesBatteryLevel%)");
    }

    if (tooltip.isNotEmpty) {
      return Tooltip(
        message: tooltip.join(", "),
        triggerMode: TooltipTriggerMode.tap,
        child: Icon(
          UniconsLine.battery_empty,
          color: tertiaryColor(context),
        ),
      );
    }
    return null;
  }
}
