import 'package:carer/widgets/alarms/alarms_bar.dart';
import 'package:carer/widgets/alarms/status_bar.dart';
import 'package:carer/widgets/colours.dart';
import 'package:carer/widgets/pages/settingspage.dart';
import 'package:flutter/material.dart';

class Bar extends StatelessWidget {
  const Bar({super.key});

  @override
  Widget build(BuildContext context) {
    List<Widget> tiles = [
      const StatusesBar(),
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
}
