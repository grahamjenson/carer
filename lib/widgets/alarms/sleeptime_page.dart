import 'package:carer/services/themes_service.dart';
import 'package:carer/utils/dates.dart';
import 'package:flutter/material.dart';

class SleepTimePage extends StatelessWidget with ThemeMixin {
  const SleepTimePage({super.key});
  static const TextStyle textStyle = TextStyle(fontSize: 50);

  static const List<int> minutesTimes = [5, 10, 20, 30, 45];
  static const List<int> hoursTimes = [1, 2, 3];
  static const List<int> timeTimes = [6, 22];

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
                  child: const Text("Cancel", style: textStyle),
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

    for (var time in minutesTimes) {
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
              style: textStyle,
            ),
          ),
        ),
      );
    }

    return minuteButtons;
  }

  List<Widget> getHourButtons(BuildContext context, ButtonStyle buttonStyle) {
    List<Widget> hourButtons = [];

    for (var time in hoursTimes) {
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
              style: textStyle,
            ),
          ),
        ),
      );
    }

    return hourButtons;
  }

  List<Widget> getTimeButtons(BuildContext context, ButtonStyle buttonStyle) {
    List<Widget> timeButtons = [];

    for (var time in timeTimes) {
      timeButtons.add(Container(
        padding: const EdgeInsets.all(5),
        child: ElevatedButton(
          style: buttonStyle,
          onPressed: () {
            Navigator.of(context).pop(Dates.secondsTillNext24HourTime(time));
          },
          child: Text(
            Dates.stringOf24HourTime(time),
            style: textStyle,
          ),
        ),
      ));
    }

    return timeButtons;
  }
}
