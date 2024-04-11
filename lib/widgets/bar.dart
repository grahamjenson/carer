import 'dart:math';

import 'package:carer/models/alarms_cn.dart';
import 'package:carer/models/settings_cn.dart';
import 'package:carer/pages/settingspage.dart';
import 'package:carer/widgets/colours.dart';
import 'package:carer/widgets/insights/window.dart';
import 'package:carer/widgets/sleepbutton.dart';
import 'package:flutter/material.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:provider/provider.dart';
import 'package:unicons/unicons.dart';

class Bar extends StatelessWidget {
  const Bar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<Settings, AlarmsCN>(
        builder: (context, settings, alarms, child) {
      // TODO dont show sleep option if all alarms are turned off

      return BottomAppBar(
        color: Colors.transparent,
        padding: const EdgeInsets.only(left: 8, right: 8),
        height: 40,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            getSleepButton(context, alarms),
            getActiveAlarms(context, alarms),
            const Expanded(
              child: SizedBox.shrink(),
            ),
            IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(
                Icons.settings,
                color: mainColor,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsPage()),
                );
              },
            ),
          ],
        ),
      );
    });
  }

  Widget getSleepButton(BuildContext context, AlarmsCN alarms) {
    return const SleepButton(
      icon: Icon(Icons.bedtime, color: mainColor),
    );
  }

  Widget getActiveAlarms(BuildContext context, AlarmsCN alarms) {
    // Returns a small container that contains the active alarm
    if (alarms.triggeredAlarms.isEmpty) {
      return const SizedBox.shrink();
    }

    List<Widget> alarmsBoxes = [];
    if (alarms.triggeredAlarms.isNotEmpty) {
      for (var alarm in alarms.triggeredAlarms) {
        alarmsBoxes.add(Text("${alarm.name} "));
      }
    }

    // return SizedBox(
    //     child: Row(
    //   children: alarmsBoxes,
    // ));
    OverlaySupportEntry? diss;
    return Container(
        padding: const EdgeInsets.only(left: 5),
        child: Listener(
          onPointerDown: (e) {
            diss = showOverlay(
              (context, t) {
                return CustomAnimationToast(
                    value: t,
                    str: alarms.triggeredAlarms
                        .map((alarm) => alarm.name)
                        .join('\n'));
              },
              duration: const Duration(seconds: 10),
            );
          },
          onPointerUp: (e) => diss?.dismiss(),
          child: TextButton(
              style: TextButton.styleFrom(
                backgroundColor: mainColor.withAlpha(40),
              ),
              onPressed: null,
              child: const SizedBox(
                  width: 20,
                  child: Icon(
                    UniconsLine.bell,
                    color: mainColor,
                    weight: 0.1,
                  ))),
        ));
  }
}

class IosStyleToast extends StatelessWidget {
  final String str;

  const IosStyleToast({super.key, required this.str});

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style:
          Theme.of(context).textTheme.bodyMedium!.copyWith(color: Colors.white),
      child: SafeArea(
        child: Align(
          alignment: const Alignment(-0.7, 0.7),
          child: Container(
            color: Colors.black,
            height: 150,
            width: 150,
            child: Window(
              title: "Alarms",
              child: Text(str),
            ),
          ),
        ),
      ),
    );
  }
}

class CustomAnimationToast extends StatelessWidget {
  final double value;

  static final Tween<Offset> tweenOffset =
      Tween<Offset>(begin: const Offset(-400, 0), end: const Offset(0, 0));

  final String str;
  const CustomAnimationToast(
      {super.key, required this.value, required this.str});

  double logTransform(double value, {double base = 20}) {
    return log((base - 1) * value + 1) / log(base);
  }

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: tweenOffset.transform(logTransform(value)),
      child: IosStyleToast(str: str),
    );
  }
}
