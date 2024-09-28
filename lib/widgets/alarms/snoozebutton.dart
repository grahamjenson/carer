import 'dart:math';

import 'package:carer/services/settings/alarm_alert_settings.dart';
import 'package:carer/services/themes_service.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/widgets/alarms/snooze_text_status.dart';
import 'package:carer/widgets/alarms/snoozetime_page.dart';
import 'package:flutter/material.dart';
import 'package:unicons/unicons.dart';

class SnoozeButton extends StatelessWidget with ThemeMixin {
  const SnoozeButton({super.key});

  @override
  Widget build(BuildContext context) {
    return AWatch(
      (context) {
        var mainColor = primaryColor(context);
        var backgroundColor = mainColor.dim.dim.dim;
        var buttonColor = mainColor.dim.dim;

        return LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) {
          var width = constraints.maxWidth - 50;
          var height = constraints.maxHeight;
          double buttonRadias = min(height, min(75, width));

          return SizedBox(
            width: width,
            height: buttonRadias,
            child: Stack(
              children: [
                getBackground(context, buttonRadias, width, backgroundColor),
                SnoozeTextStatus(buttonRadias),
                getDismissable(context, buttonRadias, width, mainColor, buttonColor),
                getSnoozeCancel(context, buttonRadias, mainColor, backgroundColor),
              ],
            ),
          );
        });
      },
      debugLabel: "SnoozeButton",
      dependencies: [AlarmAlertSettings().snoozeUntilSignal],
    );
  }

  Widget getBackground(BuildContext context, double buttonRadias, double width, Color backgroundColor) {
    return Container(
      height: buttonRadias,
      width: width,
      decoration: BoxDecoration(color: backgroundColor, borderRadius: BorderRadius.circular(10)),
      alignment: Alignment.centerLeft,
    );
  }

  Widget getSnoozeCancel(BuildContext context, double buttonRadias, Color mainColor, Color backgroundColor) {
    if (AlarmAlertSettings().snoozeDuration == null) {
      return const SizedBox.shrink();
    }

    var cancelIcon = Icon(UniconsLine.times, color: mainColor, size: buttonRadias);

    return Align(
        alignment: Alignment.topRight,
        child: Container(
          alignment: Alignment.center,
          height: buttonRadias,
          width: buttonRadias,
          decoration: BoxDecoration(color: backgroundColor, borderRadius: BorderRadius.circular(10)),
          child: IconButton(
            padding: EdgeInsets.zero,
            alignment: Alignment.center,
            icon: cancelIcon,
            onPressed: () {
              AlarmAlertSettings().setSnoozeDurationSeconds(null, "CancelButtonPushed");
            },
          ),
        ));
  }

  Widget getDismissable(BuildContext context, double buttonRadias, double width, Color mainColor, Color buttonColor) {
    Icon dismissibleIcon = Icon(UniconsLine.angle_right, color: mainColor, size: buttonRadias);

    openSnoozeDialog() async {
      var popTime = 10;

      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) {
          return SnoozeTimePage(popTime);
        }),
      );

      return true;
    }

    return Dismissible(
      key: UniqueKey(),
      direction: DismissDirection.startToEnd,
      dismissThresholds: const {DismissDirection.startToEnd: 0.5},
      confirmDismiss: (_) async {
        await go(openSnoozeDialog());
        return false;
      },
      child: Container(
        alignment: Alignment.centerLeft,
        height: buttonRadias,
        width: width - buttonRadias,
        child: Container(
          alignment: Alignment.center,
          height: buttonRadias,
          width: buttonRadias,
          decoration: BoxDecoration(color: buttonColor, borderRadius: BorderRadius.circular(10)),
          child: Center(child: dismissibleIcon),
        ),
      ),
    );
  }
}
