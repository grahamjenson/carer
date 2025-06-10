import 'package:carer/services/settings/ui_settings.dart';
import 'package:carer/services/themes_service.dart';
import 'package:carer/widgets/alarms/alarm_widget.dart';
import 'package:carer/widgets/bgl/bgl.dart';
import 'package:flutter/material.dart';
import 'package:unicons/unicons.dart';

class BGLColumn extends StatelessWidget with ThemeMixin {
  BGLColumn({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.max,
      children: [
        const Expanded(flex: 16, child: BGL()),
        const AlarmWidget(flex: 8),
        getShrinkButton(context),
      ],
    );
  }

  Widget getShrinkButton(BuildContext context) {
    if (!UISettings().focusBGL) {
      return const SizedBox();
    }
    return Flexible(
      flex: 4,
      child: IconButton(
        padding: const EdgeInsets.all(10),
        constraints: const BoxConstraints(),
        iconSize: 24,
        onPressed: () => UISettings().focusBGL = false,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor(context).bright.bright,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(3)),
          ),
        ),
        icon: Icon(
          UniconsLine.compress_alt,
          color: onBackgroundColor(context).dim,
        ),
      ),
    );
  }
}
