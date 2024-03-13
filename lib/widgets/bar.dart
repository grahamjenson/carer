import 'package:carer/models/alarms_cn.dart';
import 'package:carer/models/settings_cn.dart';
import 'package:carer/pages/settingspage.dart';
import 'package:carer/utils/dates.dart';
import 'package:carer/widgets/colours.dart';
import 'package:carer/widgets/insights/window.dart';
import 'package:carer/widgets/settings/togglebutton.dart';
import 'package:flutter/material.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:provider/provider.dart';

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
            getActiveAlarms(context, alarms),
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
    // OnPressed only cancels the sleep time, this makes it easy to turn off sleep, but hard to accidentally sleep it
    onPressed() async {
      alarms.sleepDurationSeconds = 0;
    }

    onLongPressed() async {
      var sleepTime = await openSleepDialog(context);
      sleepTime ??= 0;
      alarms.sleepDurationSeconds = sleepTime;
    }

    // There is currently a sleep value
    if (alarms.sleepDuration.inSeconds > 0) {
      return TextButton(
          style: TextButton.styleFrom(
            backgroundColor: mainColor.withAlpha(20),
          ),
          onPressed: onPressed,
          onLongPress: onLongPressed,
          child: SizedBox(
            width: 50,
            child: Text(
              textAlign: TextAlign.center,
              Dates.shortSecondsLeft(alarms.sleepDuration),
              style: const TextStyle(
                  color: mainColor, fontWeight: FontWeight.bold, height: 0.8),
            ),
          ));
    }

    return TextButton(
      style: TextButton.styleFrom(
        backgroundColor: mainColor.withAlpha(40),
      ),
      onPressed: onPressed,
      onLongPress: onLongPressed,
      child: const SizedBox(
          width: 50, child: Icon(Icons.bedtime, color: mainColor)),
    );
  }

  Widget getActiveAlarms(BuildContext context, AlarmsCN alarms) {
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

    // return SizedBox(
    //     child: Row(
    //   children: alarmsBoxes,
    // ));
    OverlaySupportEntry? diss;
    return Container(
        padding: const EdgeInsets.only(left: 5),
        child: GestureDetector(
          onTapDown: (TapDownDetails d) {
            diss = showOverlay(
              (context, t) {
                return CustomAnimationToast(
                    value: t,
                    str: alarms.triggeredAlarms
                        .map((alarm) => alarm.name)
                        .join('asd '));
              },
              duration: const Duration(seconds: 10),
            );
          },
          onTapUp: (TapUpDetails details) {
            print("safjosiafjiosa");
            diss?.dismiss();
          },
          child: TextButton(
              style: TextButton.styleFrom(
                backgroundColor: mainColor.withAlpha(40),
              ),
              onPressed: null,
              child: const SizedBox(
                  width: 20, child: Icon(Icons.alarm, color: mainColor))),
        ));
  }
}

Future<int?> openSleepDialog(BuildContext context) {
  const List<int> minutesTimes = [5, 10, 20, 30];
  const List<int> hoursTimes = [1, 2, 12, 24];
  const List<int> timeTimes = [6, 7, 21, 22];
  const TextStyle textStyle = TextStyle(fontSize: 24, height: 0.5);

  var cancelRow = TextButton.icon(
    onPressed: () {
      return Navigator.of(context).pop(0);
    },
    label: const Text("Cancel"),
    icon: const Icon(Icons.cancel),
  );
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
      Navigator.of(context)
          .pop(Dates.secondsTillNext24HourTime(timeTimes[index]));
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
          children: [minutesRow, hoursRow, timeRow, cancelRow],
        ),
      ),
    ),
  );
}

class IosStyleToast extends StatelessWidget {
  final String str;

  const IosStyleToast({super.key, required this.str});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: DefaultTextStyle(
        style: Theme.of(context)
            .textTheme
            .bodyMedium!
            .copyWith(color: Colors.white),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
              child: Container(
            color: Colors.black,
            height: 150,
            width: 150,
            child: Window(
              title: "Alarms",
              child: Text(str),
            ),
          )),
        ),
      ),
    );
  }
}

class CustomAnimationToast extends StatelessWidget {
  final double value;

  static final Tween<Offset> tweenOffset =
      Tween<Offset>(begin: const Offset(0, 10), end: const Offset(0, 0));

  static final Tween<double> tweenOpacity = Tween<double>(begin: 0, end: 1);

  final String str;
  const CustomAnimationToast(
      {super.key, required this.value, required this.str});

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: tweenOffset.transform(value),
      child: Opacity(
        opacity: tweenOpacity.transform(value),
        child: IosStyleToast(str: str),
      ),
    );
  }
}
