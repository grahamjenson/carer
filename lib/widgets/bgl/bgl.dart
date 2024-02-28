import 'package:carer/models/settings_cn.dart';
import 'package:carer/models/summary_cn.dart';
import 'package:carer/nsclient/summary.dart';
import 'package:carer/utils/dates.dart';
import 'package:carer/widgets/bgl/magarrow.dart';

import 'package:carer/widgets/colours.dart';
import 'package:carer/utils/math.dart';
import 'package:flutter/material.dart';
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
    var unit = settings.unit;

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
                  child: RichText(
                      text: TextSpan(
                    text: "${delta.age.inMinutes}",
                    style: const TextStyle(
                      color: mainColor,
                      fontWeight: FontWeight.bold,
                    ),
                    children: const [
                      TextSpan(text: "min", style: TextStyle(fontSize: 6)),
                    ],
                  )),
                ),
              ),
            ),
            FractionallySizedBox(
              widthFactor: 1,
              heightFactor: 1,
              child: FittedBox(
                child: Text(sgv.sgvStr(unit),
                    style: const TextStyle(
                      color: mainColor,
                      fontWeight: FontWeight.bold,
                    )),
              ),
            ),
            Align(
              alignment: const Alignment(0.4, 0.85),
              child: FractionallySizedBox(
                widthFactor: .5,
                heightFactor: 0.2,
                child: Row(children: [
                  Expanded(
                      child: FittedBox(
                    child: Text(
                      delta.sgvUWithSign(unit),
                      style: const TextStyle(
                        color: mainColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )),
                  const Flexible(
                      child: FractionallySizedBox(
                          heightFactor: 1, child: MagArrow())),
                ]),
              ),
            ),
          ],
        ));
  }
}
