import 'package:carer/models/settings_cn.dart';
import 'package:carer/models/summary_cn.dart';
import 'package:carer/nsclient/summary.dart';
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
                  return const Text("");
                }

                var history = summaryCn.summary.history;
                var rows = [for (var t in history) historyRow(t)];
                return Column(children: rows);
              }),
            )));
  }

  Row historyRow(ATreatment treatment) {
    return Row(children: [
      Icon(treatment.icon),
      Text(treatment.minsAgo),
      Text(treatment.description),
    ]);
  }
}
