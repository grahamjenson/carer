import 'dart:async';

import 'package:carer/services/settings/alarm_alert_settings.dart';
import 'package:carer/services/themes_service.dart';
import 'package:carer/utils/dates.dart';
import 'package:flutter/material.dart';

class SnoozeTimePage extends StatefulWidget {
  const SnoozeTimePage(this.popTime, {super.key});
  static const TextStyle textStyle = TextStyle(fontSize: 50);

  final int popTime;
  static const List<int> minutesTimes = [5, 10, 20, 30, 45];
  static const List<int> hoursTimes = [1, 2, 3];
  static const List<int> timeTimes = [6, 22];

  @override
  State<SnoozeTimePage> createState() => _SnoozeTimePageState();
}

class _SnoozeTimePageState extends State<SnoozeTimePage> with ThemeMixin {
  late Timer _timer;

  @override
  void initState() {
    super.initState();

    _timer = Timer(Duration(seconds: widget.popTime), () {
      setSnooze(null);
    });
  }

  setSnooze(int? snoozeTime) {
    snoozeTime ??= 0;
    AlarmAlertSettings().setSnoozeDurationSeconds(snoozeTime, "SnoozeDialogReturned");
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var buttonStyle = ElevatedButton.styleFrom(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8), // Square shape
        side: BorderSide(
          color: primaryColor(context),
          width: 2,
        ), // Border color and width
      ),
      minimumSize: const Size(100, 100), // Square size (width and height)
      padding: const EdgeInsets.all(10), // Remove default padding
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Snooze Alarms'),
      ),
      body: Stack(
        children: [
          GestureDetector(
            onTap: () {
              setSnooze(null);
            },
            child: Container(
              color: Colors.transparent, // Ensure the container is transparent
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            // Generate 100 widgets that display their index in the List.
            children: getSnoozeButtonsLayout(context, buttonStyle) +
                [
                  const Divider(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        setSnooze(null);
                      },
                      child: const Text("Cancel", style: SnoozeTimePage.textStyle),
                    ),
                  ),
                  const Divider(),
                ],
          ),
        ],
      ),
    );
  }

  List<Widget> getSnoozeButtonsLayout(BuildContext context, ButtonStyle buttonStyle) {
    final horizontal = MediaQuery.of(context).size.aspectRatio > 1.0;
    var mins = getMinuteButtons(context, buttonStyle);

    if (horizontal) {
      return [
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: mins,
          ),
        ),
        const Divider(),
        Expanded(
          child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: getHourButtons(context, buttonStyle) + [const VerticalDivider()] + getTimeButtons(context, buttonStyle)),
        ),
      ];
    }
    return [
      Expanded(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [mins[0], mins[1], mins[2]],
        ),
      ),
      Expanded(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [mins[3], mins[4], const SizedBox.shrink()],
        ),
      ),
      const Divider(),
      Expanded(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: getHourButtons(context, buttonStyle),
        ),
      ),
      const Divider(),
      Expanded(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: getTimeButtons(context, buttonStyle),
        ),
      ),
    ];
  }

  List<Widget> getMinuteButtons(BuildContext context, ButtonStyle buttonStyle) {
    List<Widget> minuteButtons = [];

    for (var time in SnoozeTimePage.minutesTimes) {
      minuteButtons.add(
        Container(
          padding: const EdgeInsets.all(5),
          child: ElevatedButton(
            style: buttonStyle,
            onPressed: () {
              setSnooze(time * 60);
            },
            child: Text(
              "${time}m",
              style: SnoozeTimePage.textStyle,
            ),
          ),
        ),
      );
    }

    return minuteButtons;
  }

  List<Widget> getHourButtons(BuildContext context, ButtonStyle buttonStyle) {
    List<Widget> hourButtons = [];

    for (var time in SnoozeTimePage.hoursTimes) {
      hourButtons.add(
        Container(
          padding: const EdgeInsets.all(5),
          child: ElevatedButton(
            style: buttonStyle,
            onPressed: () {
              setSnooze(time * 60 * 60);
            },
            child: Text(
              "${time}h",
              style: SnoozeTimePage.textStyle,
            ),
          ),
        ),
      );
    }

    return hourButtons;
  }

  List<Widget> getTimeButtons(BuildContext context, ButtonStyle buttonStyle) {
    List<Widget> timeButtons = [];

    for (var time in SnoozeTimePage.timeTimes) {
      timeButtons.add(Container(
        padding: const EdgeInsets.all(5),
        child: ElevatedButton(
          style: buttonStyle,
          onPressed: () {
            setSnooze(Dates.secondsTillNext24HourTime(time));
          },
          child: Text(
            Dates.stringOf24HourTime(time),
            style: SnoozeTimePage.textStyle,
          ),
        ),
      ));
    }

    return timeButtons;
  }
}
