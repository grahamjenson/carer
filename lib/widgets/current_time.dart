import 'package:carer/services/themes_service.dart';
import 'package:carer/services/timer_service.dart';
import 'package:carer/utils/futures.dart';
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';

class CurrentTimeWidget extends StatelessWidget with ThemeMixin {
  const CurrentTimeWidget({super.key});

  String _formatDateTime(DateTime dateTime) {
    //formats the dateTime as 'hh:mm' this forces each int to be 2 digits
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return AWatch(
      (context) {
        TextStyle style = displaySmall(context);
        var _ = TimerService().secondSignal.value;
        final String formattedDateTime = _formatDateTime(clock.now());
        return Text(formattedDateTime, style: style.copyWith(color: style.color!.dim));
      },
      debugLabel: "CurrentTimeWidget",
      doLog: false,
    );
  }
}
