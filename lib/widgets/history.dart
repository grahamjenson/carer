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
      return ListView(
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
    return Row(
      children: [
        Icon(
          treatment.icon,
        ),
        Text(
          Dates.dateAgoShort(treatment.age),
        ),
        Text(treatment.description),
      ],
    );
  }
}
