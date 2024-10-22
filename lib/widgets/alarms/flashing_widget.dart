import 'package:carer/services/alarms_service.dart';
import 'package:carer/services/settings/alarm_alert_settings.dart';
import 'package:carer/utils/futures.dart';
import 'package:flutter/material.dart';

class FlasthingWidget extends StatefulWidget {
  const FlasthingWidget({super.key});

  @override
  State<FlasthingWidget> createState() => _FlasthingWidgetState();
}

class _FlasthingWidgetState extends State<FlasthingWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(begin: .8, end: 0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AWatch(
      (context) {
        if (!AlarmAlertSettings().enableFlashOnAlarm || AlarmsService().alertingAlarms.value.isEmpty) {
          return const SizedBox();
        }

        return IgnorePointer(
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Opacity(
                opacity: _animation.value,
                child: Container(
                  color: Colors.white,
                  width: double.infinity,
                  height: double.infinity,
                ),
              );
            },
          ),
        );
      },
      debugLabel: "FlasthingWidget",
      dependencies: [AlarmsService().alertingAlarms],
    );
  }
}
