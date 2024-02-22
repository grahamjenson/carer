import 'dart:math';

import 'package:carer/models/settings_cn.dart';
import 'package:carer/models/summary_cn.dart';
import 'package:carer/nsclient/summary.dart';
import 'package:carer/utils/dates.dart';
import 'package:carer/widgets/bgl/magarrow.dart';

import 'package:carer/widgets/colours.dart';
import 'package:carer/utils/math.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:unicons/unicons.dart';

//copied from https://xdrip.readthedocs.io/en/latest/use/mainUI/#trend-arrow

class BGL extends StatefulWidget {
  const BGL({super.key});

  @override
  State<BGL> createState() => _BGLState();
}

class _BGLState extends State<BGL> {
  @override
  Widget build(BuildContext context) {
    return Consumer2<Settings, SummaryCN>(
        builder: (context, settings, summaryCn, child) {
      const loader = Center(child: CircularProgressIndicator());
      if (summaryCn.summary.dateRetrieved == Dates.earliest) {
        return loader;
      }

      var lastSGV = summaryCn.summary.lastSGV;
      if (lastSGV == null) {
        return loader;
      }

      var delta = summaryCn.summary.delta;
      if (delta == null) {
        return const FittedBox(child: Icon(UniconsLine.question, size: 10));
      }

      return bgl(lastSGV, delta, settings, context);
    });
  }

  Widget bgl(SGV sgv, SGV delta, Settings settings, BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    // min of screen width and height
    int minScreen = screenHeight.toInt();

    var unit = settings.unit;
    var (target, proportion) = targetRange(settings, sgv.sgv);
    var (diffTarget, diffProportion) = diffRange(delta.sgv);

    // direction up if deltat is positive down if negative
    var direction = Direction.up;
    var mag = Magnitute.small;
    switch (diffTarget) {
      case Range7.veryVeryLow:
        direction = Direction.down;
        mag = Magnitute.large;
        break;
      case Range7.veryLow:
        direction = Direction.down;
        mag = Magnitute.medium;
        break;
      case Range7.low:
        direction = Direction.down;
        mag = Magnitute.small;
        break;
      case Range7.mid:
        direction = Direction.right;
        mag = Magnitute.small;
        break;
      case Range7.high:
        direction = Direction.up;
        mag = Magnitute.small;
        break;
      case Range7.veryHigh:
        direction = Direction.up;
        mag = Magnitute.medium;
        break;
      case Range7.veryVeryHigh:
        direction = Direction.up;
        mag = Magnitute.large;
        break;
    }

    return AspectRatio(
        aspectRatio: 1.5,
        child: Stack(
          children: [
            Align(
              alignment: const Alignment(0, -0.9),
              child: FractionallySizedBox(
                widthFactor: 1,
                heightFactor: 0.2,
                child: FittedBox(
                  alignment: const Alignment(0, 0),
                  child: Text(
                    Dates.dateAgoShort(delta.age),
                    style: const TextStyle(
                      color: Color.fromARGB(255, 199, 210, 172),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            FractionallySizedBox(
              widthFactor: 1,
              heightFactor: 1,
              child: FittedBox(
                child: Text(sgv.sgvStr(unit),
                    style: const TextStyle(
                      color: Color.fromARGB(255, 199, 210, 172),
                      fontWeight: FontWeight.bold,
                    )),
              ),
            ),
            Align(
              alignment: const Alignment(0.3, 0.9),
              child: FractionallySizedBox(
                widthFactor: .5,
                heightFactor: 0.2,
                child: Row(children: [
                  Expanded(
                      child: FittedBox(
                    child: Text(
                      delta.sgvUWithSign(unit),
                      style: const TextStyle(
                        color: Color.fromARGB(255, 199, 210, 172),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )),
                  Flexible(
                      child: FractionallySizedBox(
                          heightFactor: 1.2,
                          child: MagArrow(
                            direction: direction,
                            magnitute: mag,
                          ))),
                ]),
              ),
            ),
          ],
        ));
  }
}
