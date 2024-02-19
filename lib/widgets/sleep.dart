import 'package:carer/models/settings_cn.dart';
import 'package:carer/models/summary_cn.dart';
import 'package:carer/pages/snoozepage.dart';
import 'package:carer/utils/dates.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:slide_to_act/slide_to_act.dart';

class Sleep extends StatelessWidget {
  const Sleep({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<Settings, SummaryCN>(
        builder: (context, settings, summaryCn, child) => Container(
            alignment: Alignment.center,
            child: SlideAction(
              text: "Snnoze 1346",
              sliderRotate: false,
              onSubmit: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SnoozePage()),
                );
                return null;
              },
            )));
  }
}
