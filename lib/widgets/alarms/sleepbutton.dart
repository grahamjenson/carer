import 'dart:math';

import 'package:carer/services/alarms_service.dart';
import 'package:carer/services/timer_service.dart';
import 'package:carer/utils/dates.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/widgets/colours.dart';
import 'package:carer/widgets/settings/togglebutton.dart';
import 'package:carer/widgets/smarttext.dart';
import 'package:flutter/material.dart';
import 'package:unicons/unicons.dart';

class SleepButton extends StatelessWidget {
  const SleepButton({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) {
      var width = constraints.maxWidth - 50;
      var height = constraints.maxHeight;
      double buttonRadias = min(height, min(75, width));

      return SizedBox(
        width: width,
        height: buttonRadias,
        child: Stack(
          children: [
            getSleepStatus(),
            getDismissable(context, buttonRadias, width),
            getSleepCancel(buttonRadias),
          ],
        ),
      );
    });
  }

  Widget getSleepStatus() {
    return AWatch((context) {
      var sleepString = sleepStringWidget();
      var alarmString = alarmStringWidget();

      List<Widget> rows = [];
      if (sleepString != null) {
        rows.add(sleepString);
      }
      if (alarmString != null) {
        rows.add(alarmString);
      }

      return Container(
        alignment: Alignment.center,
        padding: EdgeInsets.zero,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: rows),
      );
    }, dependencies: [TimerService().tenSecondSignal, AlarmsService().sleepUntilSignal]);
  }

  Widget getSleepCancel(double buttonRadias) {
    return AWatch(
      (context) {
        if (AlarmsService().sleepDuration == null) {
          return const SizedBox.shrink();
        }

        var backgroundColor = mainColor.withAlpha(40);
        var cancelIcon = Icon(UniconsLine.times, color: mainColor, size: buttonRadias);

        return Align(
            alignment: Alignment.topRight,
            child: Container(
              alignment: Alignment.center,
              height: buttonRadias,
              width: buttonRadias,
              decoration: BoxDecoration(color: backgroundColor, borderRadius: BorderRadius.circular(10)),
              child: IconButton(
                padding: EdgeInsets.zero,
                alignment: Alignment.center,
                icon: cancelIcon,
                onPressed: () {
                  AlarmsService().sleepDurationSeconds = null;
                },
              ),
            ));
      },
      dependencies: [AlarmsService().sleepUntilSignal],
    );
  }

  Widget getDismissable(BuildContext context, double buttonRadias, double width) {
    var backgroundColor = mainColor.withAlpha(40);
    var buttonColor = mainColor.withAlpha(80);

    var dismissibleIcon = Icon(UniconsLine.angle_right, color: mainColor, size: buttonRadias);

    openSleepDialog() async {
      var sleepTime = await _openSleepDialog(context);
      sleepTime ??= 0;
      AlarmsService().sleepDurationSeconds = sleepTime;
      return true;
    }

    return Container(
        height: buttonRadias,
        width: width,
        decoration: BoxDecoration(color: backgroundColor, borderRadius: BorderRadius.circular(10)),
        alignment: Alignment.centerLeft,
        child: Dismissible(
          key: UniqueKey(),
          direction: DismissDirection.startToEnd,
          dismissThresholds: const {DismissDirection.startToEnd: 0.5},
          confirmDismiss: (_) async {
            await go(openSleepDialog());
            return false;
          },
          child: Container(
            alignment: Alignment.centerLeft,
            height: buttonRadias,
            width: width - buttonRadias,
            child: Container(
              alignment: Alignment.center,
              height: buttonRadias,
              width: buttonRadias,
              decoration: BoxDecoration(color: buttonColor, borderRadius: BorderRadius.circular(10)),
              child: Center(child: dismissibleIcon),
            ),
          ),
        ));
  }
}

Future<int?> _openSleepDialog(BuildContext context) {
  const List<int> minutesTimes = [5, 10, 20, 30];
  const List<int> hoursTimes = [1, 2, 12, 24];
  const List<int> timeTimes = [6, 7, 21, 22];
  const TextStyle textStyle = TextStyle(fontSize: 24, height: 0.5);

  var height = 80.0;

  var minutesRow = ToggleButtons(
    constraints: BoxConstraints(maxHeight: height, maxWidth: height),
    renderBorder: true,
    borderRadius: BorderRadius.circular(10),
    borderWidth: 0,
    isSelected: List<bool>.generate(minutesTimes.length, (int index) => false),
    onPressed: (int index) {
      Navigator.of(context).pop(minutesTimes[index] * 60);
    },
    children: List<ToggleButton>.generate(
      minutesTimes.length,
      (int index) => ToggleButton(
        text: "${minutesTimes[index]}m",
        height: height,
        width: height,
        textStyle: textStyle,
      ),
    ),
  );

  var hoursRow = ToggleButtons(
    constraints: BoxConstraints(maxHeight: height, maxWidth: height),
    renderBorder: true,
    borderRadius: BorderRadius.circular(10),
    borderWidth: 0,
    isSelected: List<bool>.generate(hoursTimes.length, (int index) => false),
    onPressed: (int index) {
      Navigator.of(context).pop(hoursTimes[index] * 60 * 60);
    },
    children: List<ToggleButton>.generate(
      hoursTimes.length,
      (int index) => ToggleButton(
        text: "${hoursTimes[index]}h",
        height: height,
        width: height,
        textStyle: textStyle,
      ),
    ),
  );

  var timeRow = ToggleButtons(
    constraints: BoxConstraints(maxHeight: height, maxWidth: height),
    renderBorder: true,
    borderRadius: BorderRadius.circular(10),
    borderWidth: 0,
    isSelected: List<bool>.generate(timeTimes.length, (int index) => false),
    onPressed: (int index) {
      Navigator.of(context).pop(Dates.secondsTillNext24HourTime(timeTimes[index]));
    },
    children: List<ToggleButton>.generate(
      timeTimes.length,
      (int index) => ToggleButton(
        text: Dates.stringOf24HourTime(timeTimes[index]),
        height: height,
        width: height,
        textStyle: textStyle,
      ),
    ),
  );

  return showDialog<int>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Center(
          child: Text(
        "Snooze",
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 18),
      )),
      titlePadding: const EdgeInsets.all(5),
      contentPadding: const EdgeInsets.all(5),
      actionsPadding: const EdgeInsets.all(0),
      insetPadding: const EdgeInsets.all(0),
      content: Container(
        alignment: Alignment.center,
        height: height * 4,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          // Generate 100 widgets that display their index in the List.
          children: [minutesRow, hoursRow, timeRow],
        ),
      ),
    ),
  );
}

const big = TextStyle(
  color: mainColor,
  fontSize: 20,
  fontFeatures: [FontFeature.tabularFigures()],
);

const small = TextStyle(
  color: mainColor,
  fontSize: 10,
);

Widget? sleepStringWidget() {
  var duration = AlarmsService().sleepDuration;
  if (duration == null) {
    return null;
  }
  var totalSeconds = duration.inSeconds;
  if (totalSeconds <= 0) {
    return null;
  }

  var hours = (totalSeconds / 3600).floor();
  var minutes = ((totalSeconds % 3600) / 60).floor();

  if (hours > 0) {
    if (minutes == 0) {
      return SmartText(texts: ["Sleep $hours", "h"], styles: const [big, small]);
    }
    return SmartText(texts: ["Sleep $hours", "h", "$minutes", "m"], styles: const [big, small, big, small]);
  }

  if (minutes > 0) {
    return SmartText(texts: ["Sleep $minutes", "m"], styles: const [big, small]);
  }

  return SmartText(texts: const ["Sleep <1m"], styles: const [big]);
}

Widget? alarmStringWidget() {
  var style = small;
  // TODO fix this logic, should be seperated into its own thing
  // Should flash or pulse or something
  if (AlarmsService().sleepDuration == null) {
    style = big;
  }
  var triggeredAlarms = AlarmsService().triggeredAlarms.value;
  if (triggeredAlarms.isEmpty) {
    return null;
  }
  List<String> texts = [];
  List<TextStyle> styles = [];
  for (var alarm in triggeredAlarms) {
    texts.add(alarm.status());
    styles.add(style);
  }

  return SmartText(texts: texts, styles: styles);
}
