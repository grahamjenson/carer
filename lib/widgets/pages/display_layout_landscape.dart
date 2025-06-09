import 'package:carer/services/settings/ui_settings.dart';
import 'package:carer/services/themes_service.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/widgets/alarms/alarm_widget.dart';
import 'package:carer/widgets/bgl/bgl.dart';
import 'package:carer/widgets/insights/bgl_chart.dart';
import 'package:carer/widgets/insights/info.dart';
import 'package:carer/widgets/insights/treatments.dart';
import 'package:flutter/material.dart';

class DisplayLayoutLandscape extends StatefulWidget {
  const DisplayLayoutLandscape({super.key});

  @override
  State<DisplayLayoutLandscape> createState() => _DisplayLayoutLandscapeState();
}

class _DisplayLayoutLandscapeState extends State<DisplayLayoutLandscape> with SingleTickerProviderStateMixin, ThemeMixin {
  late AnimationController _controller;
  late final Animation<double> _curvedAnimation;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _curvedAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.linear,
    );

    _animation = Tween<double>(begin: 4, end: 10).animate(_curvedAnimation);
  }

  @override
  void dispose() {
    print("aaa REMOVING PPPPPPP A LISTENER!!!");

    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AWatch(
      (context) {
        if (UISettings().focusBGL) {
          _controller.forward(from: 0.0);
        } else {
          _controller.reverse(from: 1.0);
        }

        return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              int flex = _animation.value.toInt();
              print("aaa BGL Flex: $flex  ");

              return Row(
                children: [
                  Flexible(
                    flex: flex,
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Flexible(flex: 4, child: BGL()),
                        AlarmWidget(flex: 2),
                      ],
                    ),
                  ),
                  VerticalDivider(
                    color: outlineColor(context),
                    width: 1,
                  ),
                  Flexible(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Flexible(flex: 3, child: BGLChart()),
                        Flexible(
                          flex: 2,
                          child: Row(
                            children: [
                              Flexible(child: Treatments()),
                              Flexible(child: InfoWidget()),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              );
            });
      },
      debugLabel: "DisplayLayoutLandscape",
      dependencies: [UISettings().focusBGLSignal],
    );
  }
}
