import 'package:carer/services/alarms_service.dart';
import 'package:carer/services/settings/alarm_alert_settings.dart';
import 'package:carer/services/themes_service.dart';
import 'package:carer/utils/futures.dart';
import 'package:flutter/material.dart';

class FlasthingWidget extends StatefulWidget {
  const FlasthingWidget({super.key});

  @override
  State<FlasthingWidget> createState() => _FlasthingWidgetState();
}

class _FlasthingWidgetState extends State<FlasthingWidget> with SingleTickerProviderStateMixin, ThemeMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      lowerBound: 0,
      duration: const Duration(seconds: 1),
    )..repeat();

    _animation = CurvedAnimation(parent: _controller, curve: Curves.fastOutSlowIn);
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
              return OverflowBox(
                maxWidth: double.infinity,
                maxHeight: double.infinity,
                child: Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    _buildContainer(context, 400 * _controller.value),
                    _buildContainer(context, 600 * _controller.value),
                    _buildContainer(context, 800 * _controller.value),
                    _buildContainer(context, 1000 * _controller.value),
                    _buildContainer(context, 1500 * _controller.value),
                  ],
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

  Widget _buildContainer(BuildContext context, double radius) {
    return Container(
      width: radius,
      height: radius,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: primaryColor(context).withOpacity(0.6 * (1 - _controller.value)),
      ),
    );
  }
}
