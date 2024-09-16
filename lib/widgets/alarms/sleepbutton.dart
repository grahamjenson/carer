import 'dart:math';

import 'package:carer/services/alarms_service.dart';
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
    return LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) {
      var width = constraints.maxWidth - 50;
      var height = constraints.maxHeight;
      double buttonRadias = min(height, min(75, width));

      return SizedBox(
        width: width,
        height: buttonRadias,
        child: Stack(
          children: [
            getBackground(context, buttonRadias, width),
            const SleepTextStatus(),
            getDismissable(context, buttonRadias, width),
            getSleepCancel(context, buttonRadias),
          ],
        ),
      );
    });
  }

  Widget getBackground(BuildContext context, double buttonRadias, double width) {
    var mainColor = primaryColor(context);

    var backgroundColor = mainColor.dim.dim.dim;
    return Container(
      height: buttonRadias,
      width: width,
      decoration: BoxDecoration(color: backgroundColor, borderRadius: BorderRadius.circular(10)),
      alignment: Alignment.centerLeft,
    );
  }

  Widget getSleepCancel(BuildContext context, double buttonRadias) {
    var mainColor = primaryColor(context);

    var backgroundColor = mainColor.dim.dim.dim;

    return AWatch(
      (context) {
        if (AlarmsService().sleepDuration == null) {
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
                  AlarmsService().sleepDurationSeconds = null;
                },
              ),
            ));
      },
      dependencies: [AlarmsService().sleepUntilSignal],
      debugLabel: "SleepCancel",
    );
  }

  Widget getDismissable(BuildContext context, double buttonRadias, double width) {
    var mainColor = primaryColor(context);

    var backgroundColor = mainColor.dim.dim.dim;
    var buttonColor = mainColor.dim.dim;

    Icon dismissibleIcon = Icon(UniconsLine.angle_right, color: mainColor, size: buttonRadias);

    openSleepDialog() async {
      var sleepTime = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) {
          if (AlarmsService().sleepDuration == null) {
            AlarmsService().sleepDurationSeconds = 10;
          }
          return const SleepTimePage();
        }),
      );
      sleepTime ??= 0;
      AlarmsService().sleepDurationSeconds = sleepTime;
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
