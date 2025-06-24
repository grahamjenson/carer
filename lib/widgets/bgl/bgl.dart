import 'package:carer/models/clean_sgv.dart';
import 'package:carer/services/settings/ui_settings.dart';
import 'package:carer/services/themes_service.dart';
import 'package:carer/services/timer_service.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/utils/math.dart';
import 'package:carer/widgets/insights/window.dart';
import 'package:carer/widgets/smarttext.dart';
import 'package:flutter/material.dart';

//copied from https://xdrip.readthedocs.io/en/latest/use/mainUI/#trend-arrow

class BGL extends StatelessWidget with ThemeMixin {
  const BGL({super.key});

  TextStyle goodStyle(BuildContext context) {
    return displayLarge(context).merge(shadows()).copyWith(color: onBackgroundColor(context), fontSize: 100);
  }

  TextStyle badStyle(BuildContext context) {
    return displayLarge(context).merge(shadows(width: 1.5)).copyWith(color: primaryColor(context), fontSize: 100);
  }

  TextStyle veryBadStyle(BuildContext context) {
    return displayLarge(context).merge(shadows(width: 2)).copyWith(color: badColor(context), fontSize: 100);
  }

  Color? ageColor(BuildContext context) {
    var theme = Theme.of(context).colorScheme;

    var sgv = CleanSGV.lastSGV.value;
    if (sgv == null) {
      return theme.error;
    }

    var seconds = sgv.age.inSeconds % 300;
    if (seconds < 300) {
      return onBackgroundColor(context);
    }
    return primaryColor(context);
  }

  TextStyle sgvStyle(BuildContext context, CleanSGV sgv) {
    if (sgv.isNormal) {
      return goodStyle(context).copyWith(height: 0.8, fontWeight: FontWeight.bold);
    }
    if (sgv.isLow || sgv.isHigh) {
      return badStyle(context).copyWith(height: 0.8, fontWeight: FontWeight.bold);
    }
    return veryBadStyle(context).copyWith(height: 0.8, fontWeight: FontWeight.bold);
  }

  TextStyle diffStyle(BuildContext context, CleanSGV sgv) {
    var diffRange = sgv.diffRange;
    if (diffRange == Range5.mid) {
      return goodStyle(context);
    }
    if (diffRange == Range5.low || diffRange == Range5.high) {
      return badStyle(context);
    }
    return veryBadStyle(context);
  }

  TextStyle ageStyle(BuildContext context, CleanSGV sgv) {
    var seconds = sgv.age.inSeconds;
    if (seconds < 300) {
      return goodStyle(context);
    }
    if (seconds < 600) {
      return badStyle(context);
    }
    return veryBadStyle(context);
  }

  @override
  Widget build(BuildContext context) {
    return AWatch(
      (context) {
        const loader = Center(child: CircularProgressIndicator());
        var sgv = CleanSGV.lastSGV.value;
        if (sgv == null) {
          return loader;
        }

        var sgvS = sgvStyle(context, sgv);
        var diffS = diffStyle(context, sgv);
        var ageS = ageStyle(context, sgv);

        List<Widget> children = [
          Expanded(
            flex: 1,
            child: FittedBox(
              alignment: Alignment.bottomCenter,
              child: timeAgoReading(ageS, sgv),
            ),
          ),
          Flexible(
            flex: 4,
            child: FittedBox(
              child: Text(sgv.sgvStr(), style: sgvS),
            ),
          ),
          Expanded(
            flex: 1,
            child: FittedBox(
              alignment: Alignment.topCenter,
              child: Text(
                sgv.rate5mWithSign(),
                style: diffS,
              ),
            ),
          ),
        ];

        return GestureDetector(
          onLongPress: () => UISettings().toggleFocusBGL(),
          onDoubleTap: () => UISettings().toggleFocusBGL(),
          onScaleEnd: (ScaleEndDetails scale) {
            if (scale.pointerCount != 1) {
              return;
            }
            UISettings().toggleFocusBGL();
          },
          child: Window(
            child: FittedBox(
              alignment: const Alignment(0.0, -0.5), // This is trying to make it look better
              child: SizedBox(
                width: 150,
                height: 100,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: children,
                ),
              ),
            ),
          ),
        );
      },
      debugLabel: "BGL",
      dependencies: [TimerService().secondSignal, CleanSGV.lastSGV],
    );
  }

  Widget timeAgoReading(TextStyle baseStyle, CleanSGV sgv) {
    var seconds = sgv.age.inSeconds % 300;

    var additionalTX = "";
    if ((sgv.age.inSeconds > 300 && seconds < 20)) {
      additionalTX = " (+${seconds}s)";
    }

    var smallTS = baseStyle.copyWith(fontSize: baseStyle.fontSize! * 0.8);
    var countdownFont = smallTS.copyWith(fontSize: baseStyle.fontSize! * 0.5);

    Widget text;
    if (sgv.age.inMinutes == 0) {
      text = Text("now", style: baseStyle);
    } else {
      text = SmartText(texts: ["${sgv.age.inMinutes}", "min", additionalTX], styles: [baseStyle, smallTS, countdownFont]);
    }

    return text;
  }
}
