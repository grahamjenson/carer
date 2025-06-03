import 'dart:async';
import 'dart:math';

import 'package:carer/services/alarms_service.dart';
import 'package:carer/services/settings/alarm_alert_settings.dart';
import 'package:carer/services/settings/alarm_settings.dart';
import 'package:carer/services/themes_service.dart';
import 'package:carer/services/timer_service.dart';
import 'package:carer/services/ui/icons.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/widgets/smarttext.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SnoozeBarButton extends StatefulWidget {
  const SnoozeBarButton({super.key});

  @override
  State<SnoozeBarButton> createState() => _SnoozeBarButtonState();
}

class _SnoozeBarButtonState extends State<SnoozeBarButton> with SingleTickerProviderStateMixin, ThemeMixin {
  Timer? _pressTimer;
  Duration holdDuration = const Duration(milliseconds: 750);
  Duration reverseHoldDuration = const Duration(milliseconds: 750);
  late AnimationController _controller;
  late final Animation<double> _curvedAnimation;

  bool isSnoozing = false;
  @override
  void initState() {
    super.initState();

    isSnoozing = AlarmAlertSettings().snoozeDuration != null;
    _controller = AnimationController(
      vsync: this,
      duration: holdDuration,
      reverseDuration: reverseHoldDuration,
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _triggerAction();
        }
      });

    _curvedAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.linear,
      reverseCurve: Curves.easeOut,
    );
  }

  void _startHold() {
    if (isSnoozing) {
      GoRouter.of(context).go("/snooze");
      return; // Do not allow holding if already snoozing
    }
    _controller.forward(from: max(0.1, _curvedAnimation.value));
  }

  void _cancelHold() {
    _controller.reverse(from: _curvedAnimation.value);
  }

  void _triggerAction() {
    GoRouter.of(context).go("/snooze");
    _cancelHold();
  }

  @override
  void dispose() {
    _controller.dispose();
    _pressTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AWatch(
      (BuildContext context) {
        return GestureDetector(
          onTapDown: (_) => _startHold(),
          onTapUp: (_) => _cancelHold(),
          onTapCancel: () => _cancelHold(),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              BoxDecoration buttonDecoration = BoxDecoration(
                borderRadius: const BorderRadius.all(Radius.circular(10)),
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    primaryColor(context).withAlpha(255),
                    primaryColor(context).withAlpha(255),
                    accentColor(context).withAlpha(255),
                    accentColor(context).withAlpha(255),
                  ],
                  stops: [
                    0, _curvedAnimation.value, _curvedAnimation.value, 1.0, // The fade to transparent starts at 90% of the width
                  ],
                ),
              );
              Size size = const Size(180, 100);
              if (isSnoozing) {
                buttonDecoration = BoxDecoration(
                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                  color: primaryColor(context),
                );
              }

              ButtonStyle buttonStyle = ElevatedButton.styleFrom(
                minimumSize: size,
                maximumSize: size,
                foregroundColor: Colors.black,
                overlayColor: Colors.transparent,
                backgroundColor: Colors.transparent,
                padding: const EdgeInsets.all(5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              );

              var buttonSnooze = "Hold to Snooze";
              if (isSnoozing) {
                buttonSnooze = "Snooze";
              }
              Widget snoozeIcon = Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    CarerIcons.BAR_SNOOZE,
                    color: Colors.black,
                  ),
                  Text(buttonSnooze)
                ],
              );

              List<Widget> children = [snoozeIcon];
              if (AlarmAlertSettings().snoozeDuration != null) {
                children.add(snoozeStrings(context));
              }

              return ElevatedButton(
                clipBehavior: Clip.antiAlias,
                style: buttonStyle,
                onPressed: () {
                  if (isSnoozing) {
                    GoRouter.of(context).go("/snooze");
                  } else {
                    _controller.reverse(from: max(0.4, _curvedAnimation.value));
                  }
                },
                child: Ink(
                  width: size.width,
                  height: size.height,
                  decoration: buttonDecoration,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: children,
                  ),
                ),
              );
            },
          ),
        );
      },
      debugLabel: "SnoozeFloatingButton",
      dependencies: [
        AlarmSettings().disableAlarmsSignal,
        AlarmAlertSettings().snoozeUntilSignal,
        AlarmsService().pendingAlarms,
        TimerService().tenSecondSignal,
      ],
    );
  }

  Widget snoozeStrings(BuildContext context) {
    return Container(
      width: 80,
      height: 40,
      alignment: Alignment.center,
      child: SmartText(texts: [
        AlarmAlertSettings().snoozeDurationInMinutes(),
        "m"
      ], styles: [
        labelLarge(context).copyWith(
          height: 0.6,
          fontSize: 40,
          color: Colors.black,
        ),
        labelSmall(context).copyWith(
          height: 0.6,
          fontSize: 20,
          color: Colors.black,
        ),
      ]),
    );
  }
}
