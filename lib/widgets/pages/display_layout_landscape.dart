import 'package:carer/services/settings/ui_settings.dart';
import 'package:carer/services/themes_service.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/widgets/insights/bgl_chart.dart';
import 'package:carer/widgets/insights/bgl_column.dart';
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
  late final Animation<double> _shrinkAnimation;
  final double MIN_FLEX = 3;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    if (UISettings().focusBGL) {
      _controller.value = 1.0;
    } else {
      _controller.value = 0.0;
    }

    _curvedAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
      reverseCurve: Curves.easeInOutCubic.flipped,
    );

    _shrinkAnimation = Tween<double>(begin: 10, end: MIN_FLEX).animate(_curvedAnimation);
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
        if (UISettings().focusBGL) {
          _controller.forward();
        } else {
          _controller.reverse();
        }

        return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              var restFlex = _shrinkAnimation.value.toInt();

              List<Widget> children = [
                Flexible(
                  flex: 10,
                  child: BGLColumn(),
                ),
              ];

              if (restFlex > MIN_FLEX) {
                children.addAll(
                  [
                    VerticalDivider(
                      color: outlineColor(context),
                      width: 1,
                    ),
                    Flexible(
                      flex: restFlex,
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
              }
              return Row(
                children: children,
              );
            });
      },
      debugLabel: "DisplayLayoutLandscape",
      dependencies: [UISettings().focusBGLSignal],
    );
  }
}
