import 'package:carer/services/themes_service.dart';
import 'package:carer/widgets/alarms/alarm_widget.dart';
import 'package:carer/widgets/bgl/bgl.dart';
import 'package:carer/widgets/insights/shrink_button.dart';
import 'package:flutter/material.dart';

class BGLColumn extends StatelessWidget with ThemeMixin {
  BGLColumn({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.max,
      children: [
        Expanded(flex: 20, child: BGL()),
        AlarmWidget(flex: 8),
        ShrinkButton(),
      ],
    );
  }
}
