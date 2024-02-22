import 'dart:math';

import 'package:carer/models/settings_cn.dart';
import 'package:carer/models/summary_cn.dart';
import 'package:carer/nsclient/summary.dart';
import 'package:carer/utils/dates.dart';

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
      var sgv = delta.sgv;
      var sgvU = delta.sgvU(settings.unit);
      var (target, proportion) = range(-9, -5, 5, 9, sgv.toDouble());

      var color = Colours.diffColour(target, proportion);

      return bgl(lastSGV, delta, settings, context);
    });
  }

  Widget bgl(SGV sgv, SGV delta, Settings settings, BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    // min of screen width and height
    int minScreen = screenHeight.toInt();

    var unit = settings.unit;
    var (target, proportion) = settings.targetRange(sgv.sgv);

    var color = Colours.targetColor(target, proportion);

    // Need a number between -90 and 90
    double scaledDelta = (((delta.sgv + 24) / 48) * 180) - 90;

    // limit scaleDelta to -90 to 90 and flip
    scaledDelta = -1 * min(90, max(-90, scaledDelta));

    return AspectRatio(
        aspectRatio: 1.5,
        child: Stack(
          children: [
            FractionallySizedBox(
              widthFactor: 1,
              heightFactor: 0.2,
              child: FittedBox(
                alignment: Alignment.topCenter,
                child: Text(
                  Dates.dateAgoShort(delta.age),
                  style: const TextStyle(
                    color: Color.fromARGB(255, 199, 210, 172),
                    fontWeight: FontWeight.bold,
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
              alignment: Alignment.bottomCenter,
              child: FractionallySizedBox(
                widthFactor: 1,
                heightFactor: 0.2,
                child: FittedBox(
                  child: Text(
                    delta.sgvUWithSign(unit),
                    style: const TextStyle(
                      color: Color.fromARGB(255, 199, 210, 172),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            )
          ],
        ));
  }
}
