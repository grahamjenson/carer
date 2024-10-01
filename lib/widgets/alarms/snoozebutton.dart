import 'dart:math';

import 'package:carer/services/settings/alarm_alert_settings.dart';
import 'package:carer/services/themes_service.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/widgets/alarms/snooze_text_status.dart';
import 'package:carer/widgets/alarms/snoozetime_page.dart';
import 'package:carer/widgets/insights/window.dart';
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
          var width = constraints.maxWidth;
          var height = constraints.maxHeight - 15;
          double buttonRadias = max(20, min(height, min(75, width)));
          double betweenButtons = max(20, width - (2 * buttonRadias) - 10);

          return Window(
            child: Center(
              child: Container(
                constraints: const BoxConstraints(minWidth: 200, minHeight: 50),
                height: buttonRadias,
                width: width,
                decoration: BoxDecoration(color: backgroundColor, borderRadius: BorderRadius.circular(10)),
                child: Stack(
                  children: [
                    Center(child: SizedBox(width: betweenButtons, child: const SnoozeTextStatus())),
                    getDismissable(context, buttonRadias, width, mainColor, buttonColor),
                    getSnoozeCancel(context, buttonRadias, mainColor, buttonColor),
                  ],
                ),
              ),
            ),
          );
        });
      },
      debugLabel: "SnoozeButton",
      dependencies: [AlarmAlertSettings().snoozeUntilSignal],
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
          child: IconButton(
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.all<Color>(backgroundColor),
              shape: WidgetStateProperty.all<OutlinedBorder>(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
            ),
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
