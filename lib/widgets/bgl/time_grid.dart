import 'dart:math';

import 'package:carer/models/sgv.dart';
import 'package:carer/services/timer_service.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/widgets/colours.dart';
import 'package:flutter/material.dart';

class TimeGrid extends StatelessWidget {
  const TimeGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return AWatch((context) {
      var _ = TimerService().secondSignal.value;

      List<int> decaSeconds = List.filled(30, 0);
      var sgv = CleanSGV.lastSGV.value;
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

      return Column(
        children: grids,
      );
    });
  }

  Widget minGrid(List<int> minu) {
    List<Widget> w = [];
    for (var i = 0; i < 6; i++) {
      w.add(Container(
        decoration: BoxDecoration(
          color: mainColor.withAlpha(min(255, 80 * minu[i] + 70)),
          borderRadius: BorderRadius.circular(5), // Adjust the radius as needed
        ),
        margin: const EdgeInsets.all(2),
        width: 10,
        height: 10,
      ));
    }

    return Row(children: w);
  }
}
