import 'dart:async';

import 'package:carer/services/settings/alarm_alert_settings.dart';
import 'package:carer/services/themes_service.dart';
import 'package:carer/utils/dates.dart';
import 'package:flutter/material.dart';

class SleepTimePage extends StatefulWidget {
  const SleepTimePage({super.key});
  static const TextStyle textStyle = TextStyle(fontSize: 50);

  static const List<int> minutesTimes = [5, 10, 20, 30, 45];
  static const List<int> hoursTimes = [1, 2, 3];
  static const List<int> timeTimes = [6, 22];

  @override
  State<SleepTimePage> createState() => _SleepTimePageState();
}

class _SleepTimePageState extends State<SleepTimePage> with ThemeMixin {
  late Timer _timer;

  @override
  void initState() {
    super.initState();

    int sleepTime = 10;
    if (AlarmAlertSettings().sleepDuration == null) {
      AlarmAlertSettings().sleepDurationSeconds = sleepTime;
    }

    _timer = Timer(Duration(seconds: sleepTime), () {
      Navigator.of(context).pop();
    });
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

    var mins = getMinuteButtons(context, buttonStyle);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Snooze'),
      ),
      body: Stack(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.of(context).pop(null);
            },
            child: Container(
              color: Colors.transparent, // Ensure the container is transparent
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            // Generate 100 widgets that display their index in the List.
            children: [
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
              const Divider(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(null);
                  },
                  child: const Text("Cancel", style: SleepTimePage.textStyle),
                ),
              ),
              const Divider(),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> getMinuteButtons(BuildContext context, ButtonStyle buttonStyle) {
    List<Widget> minuteButtons = [];

    for (var time in SleepTimePage.minutesTimes) {
      minuteButtons.add(
        Container(
          padding: const EdgeInsets.all(5),
          child: ElevatedButton(
            style: buttonStyle,
            onPressed: () {
              Navigator.of(context).pop(time * 60);
            },
            child: Text(
              "${time}m",
              style: SleepTimePage.textStyle,
            ),
          ),
        ),
      );
    }

    return minuteButtons;
  }

  List<Widget> getHourButtons(BuildContext context, ButtonStyle buttonStyle) {
    List<Widget> hourButtons = [];

    for (var time in SleepTimePage.hoursTimes) {
      hourButtons.add(
        Container(
          padding: const EdgeInsets.all(5),
          child: ElevatedButton(
            style: buttonStyle,
            onPressed: () {
              Navigator.of(context).pop(time * 60 * 60);
            },
            child: Text(
              "${time}h",
              style: SleepTimePage.textStyle,
            ),
          ),
        ),
      );
    }

    return hourButtons;
  }

  List<Widget> getTimeButtons(BuildContext context, ButtonStyle buttonStyle) {
    List<Widget> timeButtons = [];

    for (var time in SleepTimePage.timeTimes) {
      timeButtons.add(Container(
        padding: const EdgeInsets.all(5),
        child: ElevatedButton(
          style: buttonStyle,
          onPressed: () {
            Navigator.of(context).pop(Dates.secondsTillNext24HourTime(time));
          },
          child: Text(
            Dates.stringOf24HourTime(time),
            style: SleepTimePage.textStyle,
          ),
        ),
      ));
    }

    return timeButtons;
  }
}
