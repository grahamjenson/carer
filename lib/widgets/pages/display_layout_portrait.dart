import 'package:carer/services/settings/ui_settings.dart';
import 'package:carer/services/themes_service.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/widgets/insights/bgl_chart.dart';
import 'package:carer/widgets/insights/bgl_column.dart';
import 'package:carer/widgets/insights/info.dart';
import 'package:carer/widgets/insights/treatments.dart';
import 'package:flutter/material.dart';

class DisplayLayoutPortrait extends StatefulWidget {
  const DisplayLayoutPortrait({super.key});

  @override
  State<DisplayLayoutPortrait> createState() => _DisplayLayoutPortraitState();
}

class _DisplayLayoutPortraitState extends State<DisplayLayoutPortrait> with SingleTickerProviderStateMixin, ThemeMixin {
  late AnimationController _controller;
  late final Animation<double> _curvedAnimation;
  late final Animation<double> _shrinkAnimation;

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

    _shrinkAnimation = Tween<double>(begin: 8, end: 0).animate(_curvedAnimation);
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
                  flex: 24,
                  child: BGLColumn(),
                )
              ];

              if (restFlex > 0) {
                children.addAll(
                  [
                    Divider(color: outlineColor(context)),
                    Flexible(flex: restFlex * 2, child: const BGLChart()),
                    Flexible(
                      flex: restFlex,
                      child: Row(
                        children: [
                          Flexible(child: Treatments()),
                          Flexible(child: InfoWidget()),
                        ],
                      ),
                    ),
                  ],
                );
              }

              return Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.max,
                children: children,
              );
            });
      },
      debugLabel: "DisplayLayoutPortrait",
      dependencies: [UISettings().focusBGLSignal],
    );
  }
}
