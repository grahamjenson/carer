import 'package:carer/models/settings_cn.dart';
import 'package:carer/models/summary_cn.dart';
import 'package:carer/utils/dates.dart';
import 'package:carer/widgets/animations.dart';
import 'package:carer/widgets/math.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:unicons/unicons.dart';

IconData trendIcon(TargetRange target, num proportion) {
  switch (target) {
    case TargetRange.veryLow:
      if (proportion > 10) {
        return UniconsLine.angle_double_down;
      }
      return UniconsLine.arrow_down;
    case TargetRange.low:
      return UniconsLine.arrow_down_right;
    case TargetRange.inRange:
      return UniconsLine.arrow_right;
    case TargetRange.high:
      return UniconsLine.arrow_up_right;
    case TargetRange.veryHigh:
      if (proportion > 10) {
        return UniconsLine.angle_double_up;
      }
      return UniconsLine.arrow_up;
  }
}

class DiffWidget extends StatefulWidget {
  const DiffWidget({super.key});

  @override
  State<DiffWidget> createState() => _DiffWidgetState();
}

class _DiffWidgetState extends State<DiffWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController animationController;
  late Animation<double> heartBeat;

  @override
  void initState() {
    super.initState();
    animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: false);

    heartBeat = heartBeatTS().animate(animationController);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<Settings, SummaryCN>(
        builder: (context, settings, summaryCn, child) {
      var delta = summaryCn.summary.delta;
      if (delta == null) {
        return const FittedBox(child: Icon(UniconsLine.question, size: 10));
      }

      var sgv = delta.sgv;
      var sgvU = delta.sgvU(settings.unit);
      var (target, proportion) = targetRange(-9, -5, 5, 9, sgv.toDouble());

      var color = targetColor(target, proportion);

      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(flex: 5),
          Expanded(flex: 2, child: deltaV(sgvU, color)),
          Expanded(flex: 4, child: trend(trendIcon(target, proportion), color)),
          Expanded(flex: 2, child: timeSince(delta.age)),
          const Spacer(flex: 5),
        ],
      );
    });
  }

  Color targetColor(TargetRange target, num proportion) {
    var color1 = Colors.red;
    var color2 = Colors.green;

    switch (target) {
      case TargetRange.veryLow:
        color1 = Colors.red;
        color2 = Colors.red;
      case TargetRange.low:
        color1 = Colors.yellow;
        color2 = Colors.red;
      case TargetRange.inRange:
        color1 = Colors.green;
        color2 = Colors.green;
      case TargetRange.high:
        color1 = Colors.red;
        color2 = Colors.yellow;
      case TargetRange.veryHigh:
        color1 = Colors.red;
        color2 = Colors.red;
    }

    return Color.lerp(color1, color2, proportion.toDouble()) ?? Colors.red;
  }

  Widget trend(IconData icon, Color color) {
    //  Icon(icon, color: color, size: 10)
    Widget icond = ScaleTransition(
      scale: heartBeat,
      child: Icon(icon, color: color, size: 10),
    );

    return FittedBox(child: icond);
  }

  Widget deltaV(double sgvU, Color color) {
    var sgvStr = sgvU.toStringAsFixed(1);

    if (sgvU == 0) {
      sgvStr = "+0";
    } else if (sgvU > 0) {
      sgvStr = "+${sgvU.toStringAsFixed(1)}";
    }

    return FittedBox(
      child: Text(
        sgvStr,
        textAlign: TextAlign.left,
        style: TextStyle(
          fontSize: 100, // Set the font size to the value you want
          height: 0.8,
          color: color,
        ),
      ),
    );
  }

  Widget timeSince(Duration age) {
    var color = Colors.white;
    if (age.inMinutes > 6) {
      color = Colors.red;
    }

    var ts = TextStyle(
      fontSize: 10,
      height: 0.8,
      color: color,
    );

    return FittedBox(
        child: Text(
      style: ts,
      Dates.dateAgoShort(age),
    ));
  }
}
