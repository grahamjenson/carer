import 'package:carer/models/settings_cn.dart';
import 'package:carer/models/summary_cn.dart';
import 'package:carer/nsclient/summary.dart';
import 'package:carer/utils/dates.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

class BGL extends StatelessWidget {
  const BGL({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<Settings, SummaryCN>(
        builder: (context, settings, summaryCn, child) => Builder(
              builder: ((context) {
                const loader = Center(child: CircularProgressIndicator());
                if (summaryCn.summary.dateRetrieved == Dates.earliest) {
                  return loader;
                }

                var lastSGV = summaryCn.summary.lastSGV;
                if (lastSGV == null) {
                  return loader;
                }

                return bglLayout(lastSGV, summaryCn, settings);
              }),
            ));
  }

  Widget bglLayout(lastSGV, summaryCn, settings) {
    return Row(children: [
      const Spacer(flex: 1),
      Expanded(flex: 32, child: bgl(lastSGV.sgvU(settings.unit))),
      Expanded(
        flex: 8,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Spacer(flex: 5),
            Expanded(
                flex: 2, child: delta(summaryCn.summary.delta(settings.unit))),
            Expanded(flex: 2, child: trend(summaryCn.summary.trendIcon)),
            Expanded(flex: 2, child: timeSince(lastSGV.dateAgo)),
            const Spacer(flex: 5),
          ],
        ),
      ),
      const Spacer(flex: 1),
    ]);
  }

  Widget bgl(double sgv) {
    return FittedBox(
        alignment: AlignmentDirectional.centerEnd,
        fit: BoxFit.fitWidth,
        child: Text(
          sgv.toStringAsFixed(1),
          textAlign: TextAlign.right,
        ));
  }

  Widget trend(IconData icon) {
    return FittedBox(child: Icon(icon));
  }

  Widget delta(double delta) {
    return FittedBox(
        child: Text(
      delta.toStringAsFixed(1),
      textAlign: TextAlign.left,
    ));
  }

  Widget timeSince(String dateStr) {
    return FittedBox(
        child: Text(
      dateStr,
    ));
  }
}
