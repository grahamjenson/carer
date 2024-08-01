import 'package:carer/services/platform_info_service.dart';
import 'package:carer/services/timer_service.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/widgets/colours.dart';
import 'package:flutter/material.dart';
import 'package:unicons/unicons.dart';

class StatusesBar extends StatelessWidget {
  const StatusesBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AWatch((_) {
      var silentStatus = getIsSilentOnIcon();
      var batteryStatus = getIsPluggedInIcon();
      List<Widget> rows = [];
      if (silentStatus != null) {
        rows.add(silentStatus);
      }
      if (batteryStatus != null) {
        rows.add(batteryStatus);
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
}
