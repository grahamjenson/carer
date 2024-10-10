import 'package:carer/services/settings/alarm_alert_settings.dart';
import 'package:carer/services/themes_service.dart';
import 'package:carer/services/timer_service.dart';
import 'package:carer/utils/futures.dart';
import 'package:flutter/material.dart';

class SnoozeTextStatus extends StatelessWidget with ThemeMixin {
  const SnoozeTextStatus({super.key});

  @override
  Widget build(BuildContext context) {
    return AWatch((context) {
      return Center(
        child: SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.contain,
            child: Text(
              "Snooze ${snoozeString()}",
              style: labelLarge(context).copyWith(color: accentColor(context).dim),
            ),
          ),
        ),
      );
    }, dependencies: [
      AlarmAlertSettings().snoozeUntilSignal,
      TimerService().tenSecondSignal, // Needed to update the time until snooze ends
    ], debugLabel: "SnoozeTextStatus");
  }

  bool isSnoozing() {
    var duration = AlarmAlertSettings().snoozeDuration;
    if (duration == null) {
      return false;
    }
    var totalSeconds = duration.inSeconds;
    if (totalSeconds <= 0) {
      return false;
    }
    return true;
  }

  String snoozeString() {
    if (!isSnoozing()) {
      return "";
    }
    var duration = AlarmAlertSettings().snoozeDuration!;
    var minutes = duration.inMinutes;
    var hours = duration.inHours;

    if (hours > 0) {
      return "${hours}h";
    }

    if (minutes > 0) {
      return "${minutes}m";
    }

    return "<1m";
  }
}
