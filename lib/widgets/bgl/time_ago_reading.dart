import 'package:carer/models/clean_sgv.dart';
import 'package:carer/services/themes_service.dart';
import 'package:carer/services/timer_service.dart';
import 'package:carer/utils/futures.dart';
import 'package:flutter/material.dart';

class TimeAgoReading extends StatelessWidget with ThemeMixin {
  const TimeAgoReading({super.key});

  @override
  Widget build(BuildContext context) {
    return AWatch(
      (context) {
        var sgv = CleanSGV.lastSGV.value;
        if (sgv == null) {
          return const SizedBox.shrink();
        }

        var aColor = ageColor(context);
        var baseFont = labelLarge(context).copyWith(height: 1).merge(shadows());
        var seconds = sgv.age.inSeconds % 300;

        var additionalTX = const Text("");
        if ((sgv.age.inSeconds > 300 && seconds < 20)) {
          additionalTX = Text(" (+${seconds}s)", style: baseFont.copyWith(fontFeatures: [const FontFeature.superscripts()]));
        }

        var mediumTS = baseFont.copyWith(fontSize: 20, color: aColor);
        var smallTS = baseFont.copyWith(color: aColor);

        Widget text;
        if (sgv.age.inMinutes == 0) {
          text = Text("now", style: mediumTS);
        } else {
          text = Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(
              "${sgv.age.inMinutes}",
              style: mediumTS,
            ),
            Text(
              "min",
              style: smallTS,
            ),
            additionalTX
          ]);
        }

        return text;
      },
      debugLabel: "TimeAgoReading",
      doLog: false,
      dependencies: [TimerService().secondSignal, CleanSGV.lastSGV],
    );
  }
}
