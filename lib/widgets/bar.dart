import 'package:carer/models/alarms_cn.dart';
import 'package:carer/models/settings_cn.dart';
import 'package:carer/pages/settingspage.dart';
import 'package:carer/utils/dates.dart';
import 'package:carer/widgets/colours.dart';
import 'package:carer/widgets/settings/togglebutton.dart';
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
            getActiveAlarms(alarms),
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
    onPressed() async {
      var sleepTime = await openSleepDialog(context);
      sleepTime ??= 0;
      alarms.sleepDurationSeconds = sleepTime;
    }

    // Todo design some safetly around accidentally turning on snooze using long press
    onLongPressed() async {
      var sleepTime = await openSleepDialog(context);
      sleepTime ??= 0;
      alarms.sleepDurationSeconds = sleepTime;
    }

    // There is currently a sleep value
    if (alarms.sleepDuration.inSeconds > 0) {
      return TextButton(
          style: TextButton.styleFrom(
            backgroundColor: Colors.black,
          ),
          onPressed: onPressed,
          onLongPress: onLongPressed,
          child: SizedBox(
              width: 60,
              child: Stack(children: [
                Center(
                    child: Icon(Icons.bedtime, color: mainColor.withAlpha(40))),
                Center(
                  child: Text(
                    Dates.shortSecondsLeft(alarms.sleepDuration),
                    style: const TextStyle(
                        color: mainColor, fontWeight: FontWeight.bold),
                  ),
                ),
              ])));
    }

    return TextButton(
        style: TextButton.styleFrom(
          backgroundColor: mainColor.withAlpha(40),
        ),
        onPressed: onPressed,
        onLongPress: onLongPressed,
        child: const SizedBox(
            width: 60,
            child: Stack(children: [
              Center(child: Icon(Icons.bedtime, color: mainColor)),
            ])));
  }

  Widget getActiveAlarms(AlarmsCN alarms) {
    // Returns a small container that contains the active alarm
    if (alarms.triggeredAlarms.isEmpty) {
      return const SizedBox.shrink();
    }
    List<Widget> alarmsBoxes = [];
    if (alarms.triggeredAlarms.isNotEmpty) {
      for (var alarm in alarms.triggeredAlarms) {
        alarmsBoxes.add(Text("${alarm.name} "));
      }
    }

    return SizedBox(
        child: Row(
      children: alarmsBoxes,
    ));
  }
}

Future<int?> openSleepDialog(BuildContext context) {
  const List<int> minutesTimes = [5, 10, 20, 30];
  const List<int> hoursTimes = [1, 2, 12, 24];
  const List<int> timeTimes = [6, 7, 21, 22];

  var cancelRow = TextButton.icon(
    onPressed: () {
      return Navigator.of(context).pop(0);
    },
    label: const Text("Cancel"),
    icon: const Icon(Icons.cancel),
  );
  var height = 80.0;
  var width = 80;
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
      Navigator.of(context)
          .pop(Dates.secondsTillNext24HourTime(timeTimes[index]));
    },
    children: List<ToggleButton>.generate(
      timeTimes.length,
      (int index) => ToggleButton(
        text: Dates.stringOf24HourTime(timeTimes[index]),
        height: height,
        width: height,
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
          children: [minutesRow, hoursRow, timeRow, cancelRow],
        ),
      ),
    ),
  );
}
