import 'package:carer/services/audio_info_service.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/widgets/alarms/alarms_bar.dart';
import 'package:carer/widgets/colours.dart';
import 'package:carer/widgets/pages/settingspage.dart';
import 'package:flutter/material.dart';
import 'package:unicons/unicons.dart';

class Bar extends StatelessWidget {
  const Bar({super.key});

  @override
  Widget build(BuildContext context) {
    List<Widget> tiles = [
      getIsSilentOnIcon(),
      const AlarmsBarIcons(),
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
  }

  Widget getSettingsButton(BuildContext context) {
    return IconButton(
      padding: EdgeInsets.zero,
      icon: const Icon(
        Icons.settings,
        color: mainColor,
      ),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SettingsPage()),
        );
      },
    );
  }

  Widget getIsSilentOnIcon() {
    return AWatch((context) {
      var ringer = AudioInfoService().ringerMode.value;
      if (ringer == RingerMode.silent || ringer == RingerMode.vibrate) {
        return Container(
            padding: const EdgeInsets.all(4), // Add padding inside the border
            decoration: BoxDecoration(
              border: Border.all(
                color: mainColor, // Color of the border
                width: 1, // Width of the border
              ),
              borderRadius: BorderRadius.circular(5), // Optional: if you want rounded corners
            ),
            child: const Tooltip(
                message: "Silent Mode",
                triggerMode: TooltipTriggerMode.tap,
                child: Icon(
                  UniconsLine.bell_slash,
                  color: mainColor,
                )));
      } else {
        return const SizedBox.shrink();
      }
    });
  }
}
