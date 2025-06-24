import 'package:carer/services/alarms_service.dart';
import 'package:carer/services/settings/alarm_alert_settings.dart';
import 'package:carer/services/settings/alarm_settings.dart';
import 'package:carer/services/settings/ui_settings.dart';
import 'package:carer/services/themes_service.dart';
import 'package:carer/services/ui/icons.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/widgets/alarms/snooze_bar_button.dart';
import 'package:carer/widgets/router.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BarBottom extends StatefulWidget {
  final bool vertical;
  const BarBottom({super.key, this.vertical = false});

  @override
  State<BarBottom> createState() => _BarBottomState();
}

class _BarBottomState extends State<BarBottom> with SingleTickerProviderStateMixin, ThemeMixin {
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

    _shrinkAnimation = Tween<double>(begin: 0, end: 30).animate(_curvedAnimation);
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
        if (UISettings().focusBGL && AlarmsService().alertingAlarms.value.isEmpty) {
          _controller.forward();
        } else {
          _controller.reverse();
        }

        var children = [
          createButton(context, "Display", CarerIcons.BAR_DISPLAY, "/display"),
          createButton(context, "Care", CarerIcons.BAR_CARE, "/care"),
          createButton(context, "Alarms", CarerIcons.BAR_ALARMS, "/alarms"),
          createButton(context, "Settings", CarerIcons.BAR_SETTINGS, "/settings"),
        ];

        NotchedShape? notchShape;
        if (!AlarmSettings().disableAlarms) {
          // Add gap for floating button
          children.insert(2, const Flexible(flex: 4, child: SnoozeBarButton()));

          notchShape = const AutomaticNotchedShape(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(15),
              ),
            ),
            RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
          );
        }

        return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              var positioned = _shrinkAnimation.value;
              if (_controller.isForwardOrCompleted) {
                return const SizedBox.shrink();
              }
              return Transform.translate(
                offset: Offset(0, positioned),
                child: BottomAppBar(
                  color: backgroundColorShade(context),
                  shape: notchShape,
                  height: 60 - (positioned / 2),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: children),
                ),
              );
            });
      },
      debugLabel: "BarBottom",
      dependencies: [
        ThemeService().themeSignal,
        AlarmAlertSettings().snoozeUntilSignal,
        AlarmSettings().disableAlarmsSignal,
        UISettings().focusBGLSignal,
      ],
    );
  }

  Widget createButton(BuildContext context, String name, IconData id, String navigateTo) {
    return Flexible(
      flex: 1,
      child: NavigationButton(
        icon: id,
        label: name,
        navigateTo: navigateTo,
      ),
    );
  }
}

class NavigationButton extends StatefulWidget {
  final IconData icon;
  final String label;

  final String navigateTo;

  const NavigationButton({
    super.key,
    required this.icon,
    required this.navigateTo,
    required this.label,
  });

  @override
  State<NavigationButton> createState() => _NavigationButtonState();
}

class _NavigationButtonState extends State<NavigationButton> with ThemeMixin {
  @override
  Widget build(BuildContext context) {
    return AWatch(
      (context) {
        var selected = currentRoute.value == widget.navigateTo;

        var color = onBackgroundColor(context);
        if (selected) {
          color = accentColor(context);
        }
        var children = [
          const Spacer(),
          Icon(
            widget.icon,
            size: 28.0,
            color: color,
            fill: 0,
          ),
          const SizedBox(height: 4.0),
          Text(
            widget.label,
            style: TextStyle(color: color, fontSize: 8),
            softWrap: false,
          ),
        ];

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: GestureDetector(
            key: ValueKey("bar_bottom_${widget.label}_$selected"),
            onTap: () {
              GoRouter.of(context).go(widget.navigateTo);
            },
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: selected ? accentColor(context) : Colors.transparent, width: selected ? 2 : 0)),
                shape: BoxShape.rectangle,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                children: children,
              ),
            ),
          ),
        );
      },
      debugLabel: "NavigationButton${widget.label}",
      dependencies: [currentRoute],
    );
  }
}
