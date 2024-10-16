import 'package:carer/services/alarms_service.dart';
import 'package:carer/services/settings/alarm_alert_settings.dart';
import 'package:carer/services/settings/ui_settings.dart';
import 'package:carer/services/themes_service.dart';
import 'package:carer/services/update_service.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/utils/logs.dart';
import 'package:carer/widgets/bar_bottom.dart';
import 'package:carer/widgets/bar_top.dart';
import 'package:carer/widgets/home_layout.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget with ThemeMixin {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        UISettings().orientation = orientation;
        Widget? bottomBar;
        if (orientation == Orientation.portrait) {
          bottomBar = const BarBottom();
        }

        return Scaffold(
          backgroundColor: backgroundColor(context),
          body: SafeArea(
            child: Stack(children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  return RefreshIndicator(
                    onRefresh: () async {
                      alog("Forcing Update");
                      UpdateService().forceUpdateAll();
                      // just to see something is happening
                      await Future.delayed(const Duration(seconds: 1));
                    },
                    displacement: 10,
                    child: SingleChildScrollView(
                      physics: const StickyRefreshPhysics(),
                      padding: EdgeInsets.zero,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: constraints.maxHeight, maxHeight: constraints.maxHeight),
                        child: HomeLayout(),
                      ),
                    ),
                  );
                },
              ),
              const PulsingContainer(),
            ]),
          ),
          appBar: const BarTop(),
          bottomNavigationBar: bottomBar,
        );
      },
    );
  }
}

class StickyRefreshPhysics extends ScrollPhysics {
  const StickyRefreshPhysics({super.parent});

  @override
  StickyRefreshPhysics applyTo(ScrollPhysics? ancestor) {
    return StickyRefreshPhysics(parent: buildParent(ancestor));
  }

  // Always draggable
  @override
  bool shouldAcceptUserOffset(ScrollMetrics position) => true;

  // Increase the distance needed to pull down to start drag, so it doesn't interfere with other interactions like chart
  @override
  double get dragStartDistanceMotionThreshold => 50;
}

class PulsingContainer extends StatefulWidget {
  const PulsingContainer({super.key});

  @override
  State<PulsingContainer> createState() => _PulsingContainerState();
}

class _PulsingContainerState extends State<PulsingContainer> with SingleTickerProviderStateMixin {
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
      debugLabel: "PulsingContainer",
      dependencies: [AlarmsService().alertingAlarms],
    );
  }
}
