import 'package:carer/models/clean_sgv.dart';
import 'package:carer/services/themes_service.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/widgets/bgl/time_ago_reading.dart';
import 'package:carer/widgets/insights/window.dart';
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

        var rColor = rangeColor(context);
        var dColor = diffColor(context);
        return Window(
          child: FittedBox(
            child: SizedBox(
              width: 15,
              height: 10,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Flexible(
                    flex: 1,
                    child: FittedBox(
                      alignment: Alignment.bottomCenter,
                      child: TimeAgoReading(),
                    ),
                  ),
                  Flexible(
                    flex: 4,
                    child: FittedBox(
                      child: Text(
                        sgv.sgvStr(),
                        style: displayLarge(context).merge(shadows()).copyWith(height: 0.8, color: rColor, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  Flexible(
                    flex: 1,
                    child: FittedBox(
                      alignment: Alignment.topCenter,
                      child: Text(
                        sgv.rate5mWithSign(),
                        style: displayLarge(context).merge(shadows()).copyWith(color: dColor, height: 0.8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      debugLabel: "BGL",
    );
  }
}
