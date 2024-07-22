import 'package:carer/models/sgv.dart';
import 'package:carer/services/timer_service.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/widgets/colours.dart';
import 'package:flutter/material.dart';

class TimeAgoReading extends StatelessWidget {
  const TimeAgoReading({super.key});

  @override
  Widget build(BuildContext context) {
    return AWatch((context) {
      var _ = TimerService().secondSignal.value;
      var sgv = CleanSGV.lastSGV().value;
      if (sgv == null) {
        return const SizedBox.shrink();
      }

      var seconds = sgv.age.inSeconds % 300;
      var additionalTX = const TextSpan(text: "");
      if ((sgv.age.inSeconds > 300 && seconds < 15)) {
        additionalTX = TextSpan(text: " (+${seconds}s)", style: const TextStyle(fontSize: 30));
      }

      Widget text;
      if (sgv.age.inMinutes == 0) {
        text = const Text(
          "now",
          style: TextStyle(
            color: mainColor,
            fontWeight: FontWeight.bold,
            fontSize: 100,
          ),
        );
      } else {
        text = RichText(
          text: TextSpan(
            text: "${sgv.age.inMinutes}",
            style: const TextStyle(
              color: mainColor,
              fontWeight: FontWeight.bold,
              fontSize: 110,
            ),
            children: [
              const TextSpan(text: "min", style: TextStyle(fontSize: 40)),
              additionalTX,
            ],
          ),
        );
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
    });
  }
}
