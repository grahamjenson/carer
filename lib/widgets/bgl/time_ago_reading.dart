import 'package:carer/models/clean_sgv.dart';
import 'package:carer/services/timer_service.dart';
import 'package:carer/utils/futures.dart';
import 'package:flutter/material.dart';

class TimeAgoReading extends StatelessWidget {
  const TimeAgoReading({super.key});

  @override
  Widget build(BuildContext context) {
    return AWatch(
      (context) {
        var _ = TimerService().secondSignal.value;
        var sgv = CleanSGV.lastSGV.value;
        if (sgv == null) {
          return const SizedBox.shrink();
        }

        var seconds = sgv.age.inSeconds % 300;
        var additionalTX = const Text("");
        if ((sgv.age.inSeconds > 300 && seconds < 15)) {
          additionalTX = Text(" (+${seconds}s)", style: const TextStyle(fontSize: 30));
        }

        Widget text;
        if (sgv.age.inMinutes == 0) {
          text = const Text(
            "now",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 100,
            ),
          );
        } else {
          text = Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(
              "${sgv.age.inMinutes}",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                height: 1,
                fontSize: 110,
              ),
            ),
            const Text("min", style: TextStyle(fontSize: 40)),
            additionalTX
          ]);
        }

        return text;
        //   return SizedBox(
        //     width: 350,
        //     height: 110,
        //     child: Row(
        //       children: [
        //         Container(padding: const EdgeInsets.only(top: 26, right: 10), child: const Expanded(flex: 1, child: TimeGrid())), // Wrapped in Expanded
        //         Expanded(flex: 3, child: text), // Wrapped in Expanded
        //       ],
        //     ),
        //   );
      },
      debugLabel: "TimeAgoReading",
      doLog: false,
    );
  }
}
