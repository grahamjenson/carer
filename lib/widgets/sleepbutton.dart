import 'package:carer/services/alarms_service.dart';
import 'package:carer/utils/dates.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/widgets/colours.dart';
import 'package:carer/widgets/settings/togglebutton.dart';
import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';

Computed<String> sleepStringSignal = acomputed(() {
  var duration = AlarmsService().sleepDuration;
  if (duration == null) {
    return "";
  }
  return Dates.shortSecondsLeft(duration);
}, "");

class SleepButton extends StatelessWidget {
  ///Change it to gave a label on a widget of your choice.
  final Widget? label;

  ///Gives a alignment to a slider icon.
  final Widget? icon;

  const SleepButton({
    super.key,
    this.label,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    var backgroundColor = mainColor.withAlpha(40);
    var buttonColor = mainColor.withAlpha(80);
    var width = 150.0;
    var height = 35.0;

    return AWatch((context) {
      // OnPressed only cancels the sleep time, this makes it easy to turn off sleep, but hard to accidentally sleep it
      stopSleep() {
        AlarmsService().sleepDurationSeconds = null;
      }

      openSleepDialog() async {
        var sleepTime = await _openSleepDialog(context);
        sleepTime ??= 0;
        AlarmsService().sleepDurationSeconds = sleepTime;
        return true;
      }

      var sleepDuration = AlarmsService().sleepDuration;
      Widget child;
      // There is currently a sleep value
      if (sleepDuration != null) {
        child = TextButton(
            style: TextButton.styleFrom(
              backgroundColor: mainColor.withAlpha(20),
            ),
            onPressed: stopSleep,
            child: SizedBox(
              width: width,
              child: Text(
                textAlign: TextAlign.center,
                sleepStringSignal.value,
                style: const TextStyle(color: mainColor, fontWeight: FontWeight.bold, height: 0.8),
              ),
            ));
      } else {
        child = Dismissible(
          key: UniqueKey(),
          direction: DismissDirection.startToEnd,
          dismissThresholds: const {DismissDirection.startToEnd: 0.75},
          confirmDismiss: (_) async {
            await go(openSleepDialog());

            return true;
          },
          child: Container(
            width: width - height,
            height: height,
            alignment: Alignment.centerLeft,
            child: Container(
              height: height,
              width: height,
              decoration: BoxDecoration(color: buttonColor, borderRadius: BorderRadius.circular(100)),
              child: Center(child: icon),
            ),
          ),
        );
      }
      return Container(
        height: height,
        width: width,
        decoration: BoxDecoration(color: backgroundColor, borderRadius: BorderRadius.circular(100)),
        alignment: Alignment.centerLeft,
        child: child,
      );
    });
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
