import 'dart:math';

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
        builder: (context, settings, summaryCn, child) {
      var history = historyContainers(settings, summaryCn);
      return Container(
          alignment: Alignment.center,
          color: Colors.green,
          child: ListView.builder(
            reverse: true,
            scrollDirection: Axis.horizontal,
            itemCount: history.length,
            itemBuilder: (context, index) {
              return history[index];
            },
          ));
    });
  }

  List<Widget> historyContainers(Settings settings, SummaryCN summaryCn) {
    if (summaryCn.summary.dateRetrieved == Dates.earliest) {
      return [];
    }
    var history = summaryCn.summary.history;
    return [for (var t in history) historyRow(t)];
  }

  Widget historyRow(ATreatment treatment) {
    return Card(
      color: Colors.blue,
      shape: const CircleBorder(),
      child: Container(
        alignment: Alignment.center,
        width: 50,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(treatment.icon, color: Colors.white, size: 15),
            Text(
              treatment.description,
              style: const TextStyle(
                color: Colors.white, // adjust color as needed
                fontSize: 12, // adjust size as needed
              ),
            ),
            Text(
              Dates.dateAgoShort(treatment.age),
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white, // adjust color as needed
                fontSize: 12, // adjust size as needed
              ),
            ),
          ],
        ),
      ),
    );
  }
}
