import 'package:carer/models/clean_sgv.dart';
import 'package:carer/services/themes_service.dart';
import 'package:carer/services/timer_service.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/widgets/smarttext.dart';
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
        var countdownFont = baseFont.copyWith(fontFeatures: [const FontFeature.superscripts()]);
        var seconds = sgv.age.inSeconds % 300;

        var additionalTX = "";
        if ((sgv.age.inSeconds > 300 && seconds < 20)) {
          additionalTX = " (+${seconds}s)";
        }

        var mediumTS = baseFont.copyWith(fontSize: 30, color: aColor);
        var smallTS = baseFont.copyWith(color: aColor, fontSize: 10);

        Widget text;
        if (sgv.age.inMinutes == 0) {
          text = Text("now", style: mediumTS);
        } else {
          text = SmartText(texts: ["${sgv.age.inMinutes}", "min", additionalTX], styles: [mediumTS, smallTS, countdownFont]);
        }

        return text;
      },
      debugLabel: "TimeAgoReading",
      doLog: false,
      dependencies: [TimerService().secondSignal, CleanSGV.lastSGV],
    );
  }
}
