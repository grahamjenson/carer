import 'dart:async';

import 'package:carer/services/settings/alarm_alert_settings.dart';
import 'package:carer/services/settings/ui_settings.dart';
import 'package:carer/services/themes_service.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/widgets/common/dialogs.dart';
import 'package:flutter/material.dart';

class SnoozeTimePage extends StatefulWidget {
  const SnoozeTimePage(this.popTime, {super.key});

  final int popTime;
  static const List<int> minutesTimes = [5, 10, 20, 30, 45];
  static const List<int> hoursTimes = [1, 2, 3, 6, 12];

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

  setSnoozeWithConfirmation(BuildContext context, int snoozeTime) async {
    bool? areYouSure =
        await Dialogs.areYouSureDialog(context, "Confirm sleep", "Are you sure you want to snooze for ${snoozeTime ~/ 3600} hours?", "Snooze");
    if (areYouSure == true) {
      AlarmAlertSettings().setSnoozeDurationSeconds(snoozeTime, "SnoozeDialogReturned");
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    } else {
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    }
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
    TextStyle textStyle = TextStyle(fontSize: 50, color: accentColor(context));
    var buttonStyle = ElevatedButton.styleFrom(
      textStyle: textStyle,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8), // Square shape
        side: BorderSide(
          color: accentColor(context),
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
          AWatch(
            (context) {
              var children = getSnoozeButtonsLayout(context, buttonStyle, textStyle) +
                  [
                    const Divider(),
                    Flexible(
                      flex: 3,
                      child: SizedBox(
                        width: double.infinity,
                        height: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            setSnooze(null);
                          },
                          child: Text("Cancel", style: textStyle),
                        ),
                      ),
                    ),
                  ];
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              );
            },
            debugLabel: "SleepPage",
            dependencies: [UISettings().orientationSignal],
          ),
        ],
      ),
    );
  }

  List<Widget> getSnoozeButtonsLayout(BuildContext context, ButtonStyle buttonStyle, TextStyle textStyle) {
    final orientation = UISettings().orientation;
    var mins = getMinuteButtons(context, buttonStyle, textStyle);
    var hours = getHourButtons(context, buttonStyle, textStyle);

    List<Widget> minsChildren = [
      Expanded(
        flex: 2,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [mins[0], mins[1], mins[2]],
        ),
      ),
      Expanded(
        flex: 2,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [mins[3], mins[4], const SizedBox.shrink()],
        ),
      ),
    ];

    List<Widget> hoursChildren = [
      Expanded(
        flex: 2,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [hours[0], hours[1], hours[2]],
        ),
      ),
      Expanded(
        flex: 2,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [hours[3], hours[4], const SizedBox.shrink()],
        ),
      ),
    ];

    if (orientation == Orientation.landscape) {
      return [
        Expanded(
          flex: 6,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: minsChildren,
                ),
              ),
              const VerticalDivider(),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: hoursChildren,
                ),
              ),
            ],
          ),
        )
      ];
    } else {
      return minsChildren + [const Divider()] + hoursChildren;
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
              setSnooze(time * 60);
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

  List<Widget> getHourButtons(BuildContext context, ButtonStyle buttonStyle, TextStyle textStyle) {
    List<Widget> hourButtons = [];

    for (var time in SnoozeTimePage.hoursTimes) {
      hourButtons.add(
        Container(
          padding: const EdgeInsets.all(5),
          child: ElevatedButton(
            style: buttonStyle,
            onPressed: () async {
              await setSnoozeWithConfirmation(context, time * 60 * 60);
            },
            child: Text(
              "${time}h",
              style: textStyle,
            ),
          ),
        ),
      );
    }

    return hourButtons;
  }
}
