import 'package:carer/models/settings_cn.dart';
import 'package:carer/models/summary_cn.dart';
import 'package:carer/utils/dates.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class History extends StatelessWidget {
  const History({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<Settings, SummaryCN>(
        builder: (context, settings, summaryCn, child) => Container(
            color: const Color.fromARGB(255, 255, 0, 0),
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

                return Center(
                    heightFactor: 2,
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          bgl(lastSGV.sgvU(settings.unit)),
                          Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                delta(summaryCn.summary.delta(settings.unit)),
                                trend(summaryCn.summary.trendIcon),
                                timeSince(lastSGV.dateAgo),
                              ]),
                        ]));
              }),
            )));
  }

  Widget bgl(double sgv) {
    return Container(
        width: 100,
        color: const Color.fromARGB(255, 0, 0, 0),
        child: FittedBox(
            fit: BoxFit.cover,
            child: Text(
              sgv.toStringAsFixed(1),
            )));
  }

  Widget trend(IconData icon) {
    return Container(
        color: const Color.fromARGB(255, 0, 0, 0),
        child: FittedBox(fit: BoxFit.cover, child: Icon(icon)));
  }

  Widget delta(double delta) {
    return Container(
        color: const Color.fromARGB(255, 0, 0, 0),
        child: FittedBox(
            fit: BoxFit.cover,
            child: Text(
              delta.toStringAsFixed(1),
            )));
  }

  Widget timeSince(String dateStr) {
    return Container(
        color: const Color.fromARGB(255, 0, 0, 0),
        child: FittedBox(
            fit: BoxFit.cover,
            child: Text(
              dateStr,
            )));
  }
}
