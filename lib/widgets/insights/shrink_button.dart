import 'package:carer/services/settings/alarm_alert_settings.dart';
import 'package:carer/services/settings/ui_settings.dart';
import 'package:carer/services/themes_service.dart';
import 'package:carer/services/timer_service.dart';
import 'package:carer/utils/futures.dart';
import 'package:flutter/material.dart';
import 'package:unicons/unicons.dart';

class ShrinkButton extends StatelessWidget with ThemeMixin {
  const ShrinkButton({super.key});

  @override
  Widget build(BuildContext context) {
    return AWatch((context) {
      if (!UISettings().focusBGL) {
        return const SizedBox.shrink();
      }
      var bgColor = backgroundColor(context).bright.bright;
      Widget snoozingWidget = const Spacer();
      if (AlarmAlertSettings().isSnoozing()) {
        snoozingWidget = Expanded(
          child: Text(
            "Snoozing ${AlarmAlertSettings().snoozeDurationInMinutes()} min",
            style: TextStyle(
              color: primaryColor(context),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      }
      return FilledButton(
        onPressed: () => UISettings().focusBGL = false,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(3)),
          ),
        ),
        child: Container(
          alignment: Alignment.center,
          color: bgColor,
          height: 60,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              snoozingWidget,
              Icon(
                UniconsLine.compress_alt,
                color: onBackgroundColor(context).dim,
                size: 25,
              ),
              const Spacer(),
            ],
          ),
        ),
      );
    }, debugLabel: "ShrinkButton", dependencies: [TimerService().fifteenSecondSignal]);
  }
}
