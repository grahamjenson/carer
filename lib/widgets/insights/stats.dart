import 'package:carer/models/settings_cn.dart';
import 'package:carer/models/summary_cn.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Stats extends StatelessWidget {
  const Stats({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<Settings, SummaryCN>(
        builder: (context, settings, summaryCn, child) {
      return Container(
        color: Colors.blue,
        child: Column(
          children: [
            Text('IOB ${summaryCn.summary.state.iob}'),
            Text('COB ${summaryCn.summary.state.cob}'),
            Text('Power ${summaryCn.summary.state.battery}'),
          ],
        ),
      );
    });
  }
}
