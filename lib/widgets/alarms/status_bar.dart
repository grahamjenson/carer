import 'package:carer/models/properties_data.dart';
import 'package:carer/services/platform_info_service.dart';
import 'package:carer/services/settings/device_settings.dart';
import 'package:carer/services/timer_service.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/widgets/colours.dart';
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:unicons/unicons.dart';

class StatusesBar extends StatelessWidget {
  const StatusesBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AWatch((_) {
      var silentStatus = getIsSilentOnIcon();
      var batteryStatus = getIsPluggedInIcon();
      var sage = sensorChangeDay();
      var cage = cannulaChangeDay();

      List<Widget> rows = [];
      if (silentStatus != null) {
        rows.add(silentStatus);
      }
      if (batteryStatus != null) {
        rows.add(batteryStatus);
      }
      if (sage != null) {
        rows.add(sage);
      }
      if (cage != null) {
        rows.add(cage);
      }

      if (rows.isEmpty) {
        return const SizedBox.shrink();
      }

      return Container(
        padding: const EdgeInsets.all(4), // Add padding inside the border
        decoration: BoxDecoration(
          border: Border.all(
            color: mainColor, // Color of the border
            width: 1, // Width of the border
          ),
          borderRadius: BorderRadius.circular(5), // Optional: if you want rounded corners
        ),
        child: Row(
          children: rows,
        ),
      );
    }, dependencies: [TimerService().fiveSecondSignal, PlatformInfoService().ringerMode, PlatformInfoService().batteryMode]);
  }

  Widget? getIsSilentOnIcon() {
    var ringer = PlatformInfoService().ringerMode.value;
    if (ringer == RingerMode.silent || ringer == RingerMode.vibrate) {
      return const Tooltip(
        message: "Silent Mode",
        triggerMode: TooltipTriggerMode.tap,
        child: Icon(
          UniconsLine.bell_slash,
          color: mainColor,
        ),
      );
    }
    return null;
  }

  Widget? getIsPluggedInIcon() {
    var battery = PlatformInfoService().batteryMode.value;
    if (battery == BatteryMode.discharging) {
      return const Tooltip(
        message: "Battery Discharging",
        triggerMode: TooltipTriggerMode.tap,
        child: Icon(
          UniconsLine.bolt_slash,
          color: mainColor,
        ),
      );
    }
    return null;
  }

  Widget? sensorChangeDay() {
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
        child: const Icon(
          UniconsLine.processor,
          color: mainColor,
        ),
      );
    }
    return null;
  }

  Widget? cannulaChangeDay() {
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
        child: const Icon(
          UniconsLine.mobile_android,
          color: mainColor,
        ),
      );
    }
    return null;
  }
}
