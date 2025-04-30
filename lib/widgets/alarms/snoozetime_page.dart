import 'dart:async';

import 'package:carer/services/settings/alarm_alert_settings.dart';
import 'package:carer/services/settings/ui_settings.dart';
import 'package:carer/services/themes_service.dart';
import 'package:carer/utils/futures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SnoozeTimePage extends StatefulWidget {
  const SnoozeTimePage({super.key});

  static const List<int> minutesTimes = [5, 10, 20, 30, 45, 60];

  @override
  State<SnoozeTimePage> createState() => _SnoozeTimePageState();
}

class _SnoozeTimePageState extends State<SnoozeTimePage> with ThemeMixin {
  late Timer _timer;

  @override
  void initState() {
    super.initState();

    _timer = Timer(const Duration(seconds: 10), () {
      // If they dont select a sleep tim within 10 seconds the snooze is cancelled and page is poped
      setSnooze(null, SnoozeReason.noButtonPressed);
    });
  }

  setSnooze(int? snoozeTime, SnoozeReason reason) {
    snoozeTime ??= 0;
    if (snoozeTime == 0) {
      AlarmAlertSettings().setSnoozeDurationSeconds(null, reason);
    } else {
      AlarmAlertSettings().setSnoozeDurationSeconds(snoozeTime, reason);
    }

    GoRouter.of(context).go("/display", extra: {'from': '/snooze'});
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    TextStyle textStyle = const TextStyle(fontSize: 50, color: ColorSchemes.primaryColor);
    var buttonStyle = ElevatedButton.styleFrom(
      textStyle: textStyle,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8), // Square shape
        side: const BorderSide(
          color: ColorSchemes.primaryColor,
          width: 2,
        ), // Border color and width
      ),
      minimumSize: const Size(100, 100), // Square size (width and height)
      padding: const EdgeInsets.all(10), // Remove default padding
    );

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Snooze Alarms'),
      ),
      body: Stack(
        children: [
          GestureDetector(
            onTap: () {
              setSnooze(null, SnoozeReason.buttonMissed);
            },
            child: Container(
              color: Colors.transparent, // Ensure the container is transparent
            ),
          ),
          AWatch(
            (context) {
              var children = getSnoozeButtonsLayout(context, buttonStyle, textStyle) +
                  [
                    Flexible(
                      flex: 3,
                      child: SizedBox(
                        width: double.infinity,
                        height: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            setSnooze(null, SnoozeReason.cancelPressed);
                          },
                          style: buttonStyle,
                          child: Text("Cancel", style: textStyle),
                        ),
                      ),
                    ),
                  ];
              return Container(
                padding: const EdgeInsets.only(top: 20, bottom: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: children,
                ),
              );
            },
            debugLabel: "SnoozePage",
            dependencies: [UISettings().orientationSignal],
          ),
        ],
      ),
    );
  }

  List<Widget> getSnoozeButtonsLayout(BuildContext context, ButtonStyle buttonStyle, TextStyle textStyle) {
    final orientation = UISettings().orientation;
    var mins = getMinuteButtons(context, buttonStyle, textStyle);

    if (orientation == Orientation.landscape) {
      return [
        Expanded(
          flex: 5,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: mins,
          ),
        )
      ];
    } else {
      return [
        Expanded(
          flex: 2,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [mins[0], mins[1]],
          ),
        ),
        Expanded(
          flex: 2,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [mins[2], mins[3]],
          ),
        ),
        Expanded(
          flex: 2,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [mins[4], mins[5]],
          ),
        ),
      ];
    }
  }

  List<Widget> getMinuteButtons(BuildContext context, ButtonStyle buttonStyle, TextStyle textStyle) {
    List<Widget> minuteButtons = [];

    for (var time in SnoozeTimePage.minutesTimes) {
      minuteButtons.add(
        Container(
          padding: const EdgeInsets.all(5),
          child: ElevatedButton(
            style: buttonStyle,
            onPressed: () {
              setSnooze(time * 60, SnoozeReason.buttonPressed);
            },
            child: Text(
              "${time}m",
              style: textStyle,
            ),
          ),
        ),
      );
    }

    return minuteButtons;
  }
}
