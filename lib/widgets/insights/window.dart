import 'package:carer/services/themes_service.dart';
import 'package:flutter/material.dart';

class Window extends StatelessWidget with ThemeMixin {
  final Widget child;
  final String? title;
  Window({super.key, required this.child, this.title});

  @override
  Widget build(BuildContext context) {
    List<Widget> children = [];
    if (title != null) {
      children.add(Container(
        alignment: Alignment.center,
        child: Text(title!,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 10,
            )),
      ));
    }
    children.add(child);
    return Container(
      margin: const EdgeInsets.all(2),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        border: Border.all(width: 0, color: outlineColor(context)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}
