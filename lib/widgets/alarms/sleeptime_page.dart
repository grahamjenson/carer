import 'package:carer/utils/dates.dart';
import 'package:flutter/material.dart';

class SleepTimePage extends StatelessWidget {
  const SleepTimePage({super.key});

  @override
  Widget build(BuildContext context) {
    const List<int> minutesTimes = [5, 10, 20, 30, 45];
    const List<int> hoursTimes = [1, 2, 3];
    const List<int> timeTimes = [6, 7, 21, 22];
    const TextStyle textStyle = TextStyle(fontSize: 30);

    var minutesRow = ToggleButtons(
      borderRadius: BorderRadius.circular(10),
      constraints: const BoxConstraints(minWidth: 80, minHeight: 80),
      borderWidth: 10,
      isSelected: List<bool>.generate(minutesTimes.length, (int index) => false),
      onPressed: (int index) {
        Navigator.of(context).pop(minutesTimes[index] * 60);
      },
      children: minutesTimes.map((time) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Text(
            "${time}m",
            style: textStyle,
          ),
        );
      }).toList(),
    );

    var hoursRow = ToggleButtons(
      borderRadius: BorderRadius.circular(10),
      constraints: const BoxConstraints(minWidth: 80, minHeight: 80),
      borderWidth: 10,
      isSelected: List<bool>.generate(hoursTimes.length, (int index) => false),
      onPressed: (int index) {
        Navigator.of(context).pop(hoursTimes[index] * 60 * 60);
      },
      children: hoursTimes.map((time) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Text(
            "${time}h",
            style: textStyle,
          ),
        );
      }).toList(),
    );

    var timeRow = ToggleButtons(
      borderRadius: BorderRadius.circular(10),
      constraints: const BoxConstraints(minWidth: 80, minHeight: 80),
      borderWidth: 10,
      isSelected: List<bool>.generate(timeTimes.length, (int index) => false),
      onPressed: (int index) {
        Navigator.of(context).pop(Dates.secondsTillNext24HourTime(timeTimes[index]));
      },
      children: timeTimes.map((int time) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Text(
            Dates.stringOf24HourTime(time),
            style: textStyle,
          ),
        );
      }).toList(),
    );

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
          Center(
            child: Container(
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                // Generate 100 widgets that display their index in the List.
                children: [
                  minutesRow,
                  hoursRow,
                  timeRow,
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop(null);
                      },
                      child: const Text("Cancel", style: textStyle),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
