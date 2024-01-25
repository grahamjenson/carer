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
        builder: (context, settings, summaryCn, child) => Container(
            color: const Color.fromARGB(255, 0, 0, 0),
            alignment: Alignment.center,
            child: Builder(
              builder: ((context) {
                if (summaryCn.summary.dateRetrieved == Dates.earliest) {
                  return const CircularProgressIndicator();
                }

                var lastSGV = summaryCn.summary.lastSGV;
                if (lastSGV == null) {
                  return const CircularProgressIndicator();
                }

                return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                          flex: 4, child: bgl(lastSGV.sgvU(settings.unit))),
                      Expanded(
                          flex: 3,
                          child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Spacer(
                                  flex: 6,
                                ),
                                Expanded(
                                    flex: 2,
                                    child: delta(summaryCn.summary
                                        .delta(settings.unit))),
                                Expanded(
                                    flex: 2,
                                    child: trend(summaryCn.summary.trendIcon)),
                                Expanded(
                                    flex: 2, child: timeSince(lastSGV.dateAgo)),
                                const Spacer(flex: 6),
                              ])),
                    ]);
              }),
            )));
  }

  Widget bgl(double sgv) {
    return FittedBox(
        alignment: AlignmentDirectional.centerEnd,
        fit: BoxFit.fitHeight,
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
