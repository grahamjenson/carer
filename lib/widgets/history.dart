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
      var width = MediaQuery.of(context).size.width;

      // minSize of container
      const int minWidth = 300;
      const int minHeight = 60;
      var count = max(1, width / minWidth).toInt();
      var ratio = (width / count) / minHeight;
      return GridView.count(
        crossAxisCount: count,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: ratio,
        children: historyContainers(settings, summaryCn),
      );
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
    return SizedBox(
      child: Card(
        child: ListTile(
          leading: Icon(treatment.icon),
          title: Text(
            treatment.description,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Text(Dates.dateAgoShort(treatment.age)),
        ),
      ),
    );
  }
}
