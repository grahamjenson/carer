import 'package:carer/services/themes_service.dart';
import 'package:carer/services/update_service.dart';
import 'package:carer/utils/logs.dart';
import 'package:carer/widgets/bar.dart';
import 'package:carer/widgets/home_layout.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget with ThemeMixin {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: surfaceColor(context),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => RefreshIndicator(
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
          ),
        ),
      ),
      bottomNavigationBar: const Bar(),
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
