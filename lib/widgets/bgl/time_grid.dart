import 'package:carer/models/sgv.dart';
import 'package:carer/services/timer_service.dart';
import 'package:carer/widgets/colours.dart';
import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';

class TimeGrid extends StatelessWidget {
  const TimeGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      var _ = TimerService().secondSignal.value;
      List<int> decaSeconds = List.filled(30, 0);
      var sgv = SGV.lastSGV().value;
      if (sgv == null) {
        return const SizedBox.shrink();
      }

      // Calculate the number of seconds
      var seconds = sgv.age.inSeconds % 300;
      var decSeconds = (seconds / 10).truncate();
      int intensity = (sgv.age.inMinutes ~/ 5) + 1;
      for (var i = 0; i < decSeconds; i++) {
        decaSeconds[i] = intensity;
      }

      var min1 = decaSeconds.sublist(0, 6);
      var min2 = decaSeconds.sublist(6, 12);
      var min3 = decaSeconds.sublist(12, 18);
      var min4 = decaSeconds.sublist(18, 24);
      var min5 = decaSeconds.sublist(24, 30);

      List<Widget> grids = [
        minGrid(min1),
        minGrid(min2),
        minGrid(min3),
        minGrid(min4),
        minGrid(min5),
      ];
      return SizedBox(
        height: 8,
        width: 160,
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            crossAxisSpacing: 2,
            mainAxisSpacing: 1,
          ),
          itemCount: 5,
          itemBuilder: (context, index) {
            return grids[index];
          },
        ),
      );
    });
  }

  Widget minGrid(List<int> min) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: mainColor.withAlpha(80 * min[index] + 40),
            borderRadius: BorderRadius.circular(1), // Adjust the radius as needed
          ),
          margin: const EdgeInsets.all(1),
          width: 4,
          height: 4,
        );
      },
    );
  }
}
