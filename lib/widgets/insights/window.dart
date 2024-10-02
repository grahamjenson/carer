import 'package:carer/services/themes_service.dart';
import 'package:flutter/material.dart';

class Window extends StatelessWidget with ThemeMixin {
  final Widget child;
  Window({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    var color = backgroundColorShade(context);
    return SizedBox.expand(
        child: Container(
      margin: const EdgeInsets.all(2),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        border: Border.all(
          width: 0,
          color: color,
        ),
        borderRadius: BorderRadius.circular(12),
        color: color,
      ),
      padding: const EdgeInsets.all(5),
      child: child,
    ));
  }
}
