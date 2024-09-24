import 'package:carer/models/clean_sgv.dart';
import 'package:carer/services/settings/ui_settings.dart';
import 'package:carer/services/themes_service.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/widgets/bgl/time_ago_reading.dart';
import 'package:flutter/material.dart';

//copied from https://xdrip.readthedocs.io/en/latest/use/mainUI/#trend-arrow

class BGL extends StatelessWidget with ThemeMixin {
  const BGL({super.key});

  @override
  Widget build(BuildContext context) {
    return AWatch(
      (context) {
        const loader = Center(child: CircularProgressIndicator());
        var sgv = CleanSGV.lastSGV.value;
        if (sgv == null) {
          return loader;
        }
        var unit = UISettings().unit;

        var rColor = rangeColor(context);
        var dColor = diffColor(context);
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
                Align(
                    alignment: const Alignment(0, 0.6),
                    child: FractionallySizedBox(
                      widthFactor: 1,
                      heightFactor: 0.85,
                      child: FittedBox(
                        child: Text(
                          sgv.sgvStr(unit),
                          style: displayLarge(context).merge(shadows()).copyWith(color: rColor),
                        ),
                      ),
                    )),
                Align(
                  alignment: const Alignment(-0.2, 1.06),
                  child: FractionallySizedBox(
                    widthFactor: .5,
                    heightFactor: 0.2,
                    child: Row(children: [
                      Expanded(
                        child: FittedBox(
                            child: Text(
                          sgv.rate5mWithSign(unit),
                          style: displayLarge(context).merge(shadows()).copyWith(color: dColor),
                        )),
                      ),
                    ]),
                  ),
                ),
              ],
            ));
      },
      debugLabel: "BGL",
    );
  }
}
