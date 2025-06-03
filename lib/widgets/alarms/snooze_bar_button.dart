import 'dart:async';

import 'package:carer/services/alarms_service.dart';
import 'package:carer/services/settings/alarm_alert_settings.dart';
import 'package:carer/services/settings/alarm_settings.dart';
import 'package:carer/services/themes_service.dart';
import 'package:carer/services/timer_service.dart';
import 'package:carer/services/ui/icons.dart';
import 'package:carer/utils/futures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SnoozeBarButton extends StatefulWidget {
  const SnoozeBarButton({super.key});

  @override
  State<SnoozeBarButton> createState() => _SnoozeBarButtonState();
}

class _SnoozeBarButtonState extends State<SnoozeBarButton> with SingleTickerProviderStateMixin, ThemeMixin {
  Timer? _pressTimer;
  Duration holdDuration = const Duration(milliseconds: 1000);
  Duration reverseHoldDuration = const Duration(milliseconds: 1000);
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
      curve: Curves.easeOut,
      reverseCurve: Curves.linear,
    );
  }

  void _startHold() {
    if (isSnoozing) {
      return; // Do not allow holding if already snoozing
    }
    _controller.forward(from: 0.5);
  }

  void _cancelHold() {
    _controller.reverse();
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
        Color buttonBackGroundColor = accentColor(context);
        Size size = const Size(140, 50);
        if (isSnoozing) {
          buttonBackGroundColor = primaryColor(context);
          size = const Size(170, 50);
        }

        ButtonStyle buttonStyle = ElevatedButton.styleFrom(
          minimumSize: size,
          maximumSize: size,
          splashFactory: null,
          foregroundColor: Colors.black,
          overlayColor: Colors.transparent,
          backgroundColor: buttonBackGroundColor,
          padding: const EdgeInsets.all(5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        );

        Widget snoozeIcon = const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CarerIcons.BAR_SNOOZE,
              color: Colors.black,
            ),
            Text("Snooze")
          ],
        );

        List<Widget> children = [snoozeIcon];
        if (AlarmAlertSettings().snoozeDuration != null) {
          children.add(snoozeStrings(context));
        }

        return GestureDetector(
          onTapDown: (_) => _startHold(),
          onTapUp: (_) => _cancelHold(),
          onTapCancel: () => _cancelHold(),
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              ElevatedButton(
                clipBehavior: Clip.antiAlias,
                style: buttonStyle,
                onPressed: () {
                  if (isSnoozing) {
                    GoRouter.of(context).go("/snooze");
                  } else {
                    _controller.reverse(from: 0.9);
                  }
                },
                child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: children),
              ),
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  if (isSnoozing) {
                    return const SizedBox.shrink();
                  }
                  var v = (_curvedAnimation.value);
                  var height = size.height * v;
                  var width = size.width;
                  if (height < 10) {
                    width = width - 10;
                  }
                  return ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(10),
                      bottomLeft: Radius.circular(10),
                      topRight: Radius.circular(10),
                      bottomRight: Radius.circular(10),
                    ),
                    child: Container(
                      width: width,
                      height: height,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(bottomRight: Radius.circular(10), bottomLeft: Radius.circular(10)),
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            primaryColor(context).withAlpha(200),
                            primaryColor(context).withAlpha(200),
                            primaryColor(context).withAlpha(150),
                            primaryColor(context).withAlpha(100),
                          ],
                          stops: const [
                            0.0, 0.4, 0.7, 1.0, // The fade to transparent starts at 90% of the width
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
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
      width: 100,
      height: 40,
      alignment: Alignment.center,
      child: Text(
        AlarmAlertSettings().snoozeString(),
        style: labelLarge(context).copyWith(
          height: 0.6,
          fontSize: 40,
          color: Colors.black,
        ),
      ),
    );
  }
}
