import 'package:carer/models/sgv.dart';
import 'package:carer/services/timer_service.dart';
import 'package:carer/widgets/bgl/time_grid.dart';
import 'package:carer/widgets/colours.dart';
import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';

class TimeAgoReading extends StatelessWidget {
  const TimeAgoReading({super.key});

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      var _ = TimerService().secondSignal.value;
      var sgv = SGV.lastSGV().value;
      if (sgv == null) {
        return const SizedBox.shrink();
      }

      var seconds = sgv.age.inSeconds % 300;
      var additionalTX = const TextSpan(text: "");
      if ((sgv.age.inSeconds > 300 && seconds < 15)) {
        additionalTX = TextSpan(text: " (+${seconds}s)", style: const TextStyle(fontSize: 3));
      }

      Widget text;
      if (sgv.age.inMinutes == 0) {
        text = const Text(
          "now",
          style: TextStyle(
            color: mainColor,
            fontWeight: FontWeight.bold,
          ),
        );
      } else {
        text = RichText(
          text: TextSpan(
            text: "${sgv.age.inMinutes}",
            style: const TextStyle(
              color: mainColor,
              fontWeight: FontWeight.bold,
            ),
            children: [
              const TextSpan(text: "min", style: TextStyle(fontSize: 6)),
              additionalTX,
            ],
          ),
        );
      }

      return SizedBox(
          height: 25,
          width: 120,
          child: Stack(
            children: [
              Align(
                alignment: Alignment.center,
                child: FittedBox(
                  child: text,
                ),
              ),
              const Align(
                alignment: Alignment(0, 1),
                child: FractionallySizedBox(
                  child: FittedBox(
                    child: TimeGrid(),
                  ),
                ),
              ),
            ],
          ));
    });
  }
}
