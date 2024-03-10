import 'package:carer/models/alarms_cn.dart';
import 'package:carer/models/settings_cn.dart';
import 'package:carer/pages/settingspage.dart';
import 'package:carer/utils/dates.dart';
import 'package:carer/widgets/colours.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:slide_to_act/slide_to_act.dart';

class Bar extends StatelessWidget {
  const Bar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<Settings, AlarmsCN>(
        builder: (context, settings, alarms, child) {
      // TODO dont show sleep option if all alarms are turned off

      return BottomAppBar(
        color: Colors.transparent,
        padding: const EdgeInsets.only(left: 8, right: 8),
        height: 40,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            getSleepButton(context, alarms),
            const Expanded(
              child: SizedBox.shrink(),
            ),
            IconButton(
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
            ),
          ],
        ),
      );
    });
  }

  Widget getSleepButton(BuildContext context, AlarmsCN alarms) {
    var text = "Snooze";
    if (alarms.sleepDuration != 0) {
      text = Dates.shortSecondsLeft(alarms.sleepDuration);
    }
    if (alarms.triggeredAlarms.isNotEmpty) {
      for (var alarm in alarms.triggeredAlarms) {
        text += "${alarm.name} ";
      }
    }
    return TextButton(
        style: TextButton.styleFrom(
          backgroundColor: mainColor,
        ),
        child: Stack(children: [
          Center(child: Icon(Icons.bedtime, color: Colors.black.withAlpha(75))),
          Center(
            child: Text(
              text,
              style: const TextStyle(color: Colors.black),
            ),
          ),
        ]),
        onPressed: () async {
          var sleepTime = await openSleepDialog(context);
          sleepTime ??= 0;
          alarms.sleepDurationSeconds = sleepTime;
        });
  }
}

Future<int?> openSleepDialog(BuildContext context) {
  const List<int> minutesTimes = [5, 10, 20, 30];
  const List<int> hoursTimes = [1, 2, 12, 24];
  const List<int> timeTimes = [6, 7, 21, 22];

  var cancelRow = Row(
    children: [
      TextButton.icon(
        onPressed: () {
          return Navigator.of(context).pop(0);
        },
        label: const Text("Cancel"),
        icon: const Icon(Icons.cancel),
      )
    ],
  );
  ButtonStyle stle = ButtonStyle(
    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(0.0))),
    padding:
        MaterialStateProperty.all<EdgeInsetsGeometry>(const EdgeInsets.all(8)),
    fixedSize: MaterialStateProperty.all<Size>(const Size(40, 40)),
    visualDensity: VisualDensity.compact,
  );

  List<Widget> minutesButtons = [
    for (var time in minutesTimes)
      OutlinedButton(
        style: stle,
        onPressed: () {
          Navigator.of(context).pop(time * 60);
        },
        child: Text(Dates.shortSecondsLeft(Duration(seconds: time * 60))),
      )
  ];

  List<Widget> hoursButtons = [
    for (var time in hoursTimes)
      OutlinedButton(
        style: stle,
        onPressed: () {
          Navigator.of(context).pop(time * 60 * 60);
        },
        child: Text(Dates.shortSecondsLeft(Duration(seconds: time * 60 * 60))),
      )
  ];

  List<Widget> timeButtons = [
    for (var time in timeTimes)
      OutlinedButton(
        style: stle,
        onPressed: () {
          Navigator.of(context).pop(Dates.secondsTillNext24HourTime(time));
        },
        child: Text(Dates.stringOf24HourTime(time)),
      )
  ];

  var minutesRow = Row(children: minutesButtons);
  var hoursRow = Row(children: hoursButtons);
  var timeRow = Row(children: timeButtons);

  return showDialog<int>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("Snooze"),
      content: Container(
        alignment: Alignment.center,
        height: 200,
        child: Column(
          // Generate 100 widgets that display their index in the List.
          children: [minutesRow, hoursRow, timeRow, cancelRow],
        ),
      ),
    ),
  );
}
