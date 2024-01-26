import 'package:carer/models/settings_cn.dart';
import 'package:carer/models/summary_cn.dart';
import 'package:carer/nsclient/summary.dart';
import 'package:carer/utils/dates.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

const ts = TextStyle(
  fontSize: 100, // Set the font size to the value you want
  height: 0.8,
);

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
    ]);
  }

  Widget bgl(double sgv) {
    var lowerTarget = 4;
    var upperTarget = 10;

    return Container(
      padding: const EdgeInsets.all(8),
      child: FittedBox(
        alignment: AlignmentDirectional.centerEnd,
        fit: BoxFit.contain,
        child: Text(
          sgv.toStringAsFixed(1),
          textAlign: TextAlign.right,
          style: TextStyle(
            fontSize: 100,
            height: 0.8,
            color: (sgv < lowerTarget || sgv > upperTarget)
                ? Colors.red
                : Colors.green,
          ),
        ),
      ),
    );
  }

  Widget trend(IconData icon) {
    return FittedBox(child: Icon(icon));
  }

  Widget delta(double delta) {
    return FittedBox(
        child: Text(
      delta.toStringAsFixed(1),
      textAlign: TextAlign.left,
      style: ts,
    ));
  }

  Widget timeSince(String dateStr) {
    return FittedBox(
        child: Text(
      style: ts,
      dateStr,
    ));
  }
}
