import 'package:carer/models/sgv.dart';
import 'package:carer/services/settings/ui_settings.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/widgets/bgl/magarrow.dart';
import 'package:carer/widgets/bgl/time_ago_reading.dart';
import 'package:carer/widgets/colours.dart';
import 'package:flutter/material.dart';

//copied from https://xdrip.readthedocs.io/en/latest/use/mainUI/#trend-arrow

class BGL extends StatelessWidget {
  const BGL({super.key});

  @override
  Widget build(BuildContext context) {
    return AWatch((context) {
      const loader = Center(child: CircularProgressIndicator());

      var sgv = CleanSGV.lastSGV().value;
      if (sgv == null) {
        return loader;
      }

      return AspectRatio(
          aspectRatio: 1.5,
          child: Stack(
            children: [
              const Align(
                alignment: Alignment(0, -0.9),
                child: FractionallySizedBox(
                  widthFactor: 1,
                  heightFactor: 0.2,
                  child: FittedBox(
                    alignment: Alignment(0, 0),
                    child: TimeAgoReading(),
                  ),
                ),
              ),
              FractionallySizedBox(
                widthFactor: 1,
                heightFactor: 1,
                child: FittedBox(
                  child: AWatch((_) {
                    var unit = UISettings().unit;
                    return Text(sgv.sgvStr(unit),
                        style: const TextStyle(
                          color: mainColor,
                          fontWeight: FontWeight.bold,
                        ));
                  }),
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
                        child: AWatch((_) {
                          var unit = UISettings().unit;
                          return Text(
                            sgv.rate5mWithSign(unit),
                            style: const TextStyle(
                              color: mainColor,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }),
                      ),
                    ),
                    const Flexible(child: FractionallySizedBox(heightFactor: 1, child: MagArrow())),
                  ]),
                ),
              ),
            ],
          ));
    });
  }
}
