import 'dart:math';

import 'package:carer/services/alarms_service.dart';
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
        var mainColor = accentColor(context);
        var bColor = backgroundColorShade(context);
        var buttonColor = mainColor.dim.dim;

        return LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) {
          var width = constraints.maxWidth;
          var height = constraints.maxHeight;
          double buttonRadias = max(20, min(height, min(100, width)));

          // If there is one button

          return Center(
            child: Container(
              margin: const EdgeInsets.all(2),
              height: buttonRadias,
              width: width,
              decoration: BoxDecoration(color: bColor, borderRadius: BorderRadius.circular(10)),
              child: Stack(
                children: getTexts(context, width, buttonRadias) +
                    [
                      getDismissable(context, buttonRadias, width, mainColor, buttonColor),
                      getSnoozeCancel(context, buttonRadias, mainColor, buttonColor),
                    ],
              ),
            ),
          );
        });
      },
      debugLabel: "SnoozeButton",
      dependencies: [AlarmAlertSettings().snoozeUntilSignal, AlarmsService().pendingAlarms],
    );
  }

  List<Widget> getTexts(BuildContext context, double width, double buttonRadias) {
    double betweenButtons = width - buttonRadias * 2 - 20;

    betweenButtons = max(20, betweenButtons);

    var alarmW = alarmStringWidget(context);
    if (alarmW != null) {
      return [
        Align(
          alignment: Alignment.topCenter,
          child: SizedBox(width: betweenButtons, height: buttonRadias * 2 / 3, child: const SnoozeTextStatus()),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: SizedBox(width: betweenButtons, height: buttonRadias * 1 / 3, child: alarmStringWidget(context)),
        ),
      ];
    }

    return [
      Align(
        alignment: Alignment.center,
        child: SizedBox(width: betweenButtons, height: buttonRadias, child: const SnoozeTextStatus()),
      ),
    ];
  }

  Widget? alarmStringWidget(BuildContext context) {
    var small = TextStyle(
      fontSize: 10,
      color: primaryColor(context),
    );

    var pendingAlarms = AlarmsService().pendingAlarms.value;
    if (pendingAlarms.isEmpty) {
      return null;
    }

    var alarmStrings = [];
    for (var alarm in pendingAlarms) {
      alarmStrings.add(alarm.shortSummary());
    }

    return Center(
      child: SizedBox.expand(child: FittedBox(fit: BoxFit.contain, child: Text(alarmStrings.join("\n"), style: small))),
    );
  }

  Widget getSnoozeCancel(BuildContext context, double buttonRadias, Color mainColor, Color bColor) {
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
              backgroundColor: WidgetStateProperty.all<Color>(bColor),
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
