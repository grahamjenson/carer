import 'dart:math';

import 'package:carer/services/settings/alarm_alert_settings.dart';
import 'package:carer/services/themes_service.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/widgets/alarms/sleep_text_status.dart';
import 'package:carer/widgets/alarms/sleeptime_page.dart';
import 'package:flutter/material.dart';
import 'package:unicons/unicons.dart';

class SleepButton extends StatelessWidget with ThemeMixin {
  const SleepButton({super.key});

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
                SleepTextStatus(buttonRadias),
                getDismissable(context, buttonRadias, width, mainColor, buttonColor),
                getSleepCancel(context, buttonRadias, mainColor, backgroundColor),
              ],
            ),
          );
        });
      },
      debugLabel: "SleepButton",
      dependencies: [AlarmAlertSettings().sleepUntilSignal],
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

  Widget getSleepCancel(BuildContext context, double buttonRadias, Color mainColor, Color backgroundColor) {
    if (AlarmAlertSettings().sleepDuration == null) {
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
              AlarmAlertSettings().setSleepDurationSeconds(null, "CancelButtonPushed");
            },
          ),
        ));
  }

  Widget getDismissable(BuildContext context, double buttonRadias, double width, Color mainColor, Color buttonColor) {
    Icon dismissibleIcon = Icon(UniconsLine.angle_right, color: mainColor, size: buttonRadias);

    openSleepDialog() async {
      var popTime = 10;

      var sleepTime = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) {
          return SleepTimePage(popTime);
        }),
      );
      sleepTime ??= 0;
      AlarmAlertSettings().setSleepDurationSeconds(sleepTime, "SleepDialogReturned");
      return true;
    }

    return Dismissible(
      key: UniqueKey(),
      direction: DismissDirection.startToEnd,
      dismissThresholds: const {DismissDirection.startToEnd: 0.5},
      confirmDismiss: (_) async {
        await go(openSleepDialog());
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
