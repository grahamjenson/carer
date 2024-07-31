import 'dart:math';

import 'package:carer/services/alarms_service.dart';
import 'package:carer/widgets/colours.dart';
import 'package:carer/widgets/insights/window.dart';
import 'package:flutter/material.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:unicons/unicons.dart';

class ActiveAlarms extends StatelessWidget {
  const ActiveAlarms({super.key});

  @override
  Widget build(BuildContext context) {
    var triggeredAlarms = AlarmsService().triggeredAlarms.value;

    if (triggeredAlarms.isEmpty) {
      return const SizedBox.shrink();
    }

    OverlaySupportEntry? diss;
    return Container(
        padding: const EdgeInsets.only(left: 5),
        child: Listener(
          onPointerDown: (e) {
            diss = showOverlay(
              (context, t) {
                return CustomAnimationToast(value: t, str: triggeredAlarms.map((alarm) => alarm.status()).join('\n'));
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
      style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Colors.white),
      child: SafeArea(
        child: Align(
          alignment: const Alignment(-0.7, 0.7),
          child: Container(
            color: Colors.black,
            height: 150,
            width: 300,
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

  static final Tween<Offset> tweenOffset = Tween<Offset>(begin: const Offset(-400, 0), end: const Offset(0, 0));

  final String str;
  const CustomAnimationToast({super.key, required this.value, required this.str});

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
