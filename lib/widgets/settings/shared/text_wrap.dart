import 'package:flutter/material.dart';

class TextWrap extends StatelessWidget {
  final Widget child;
  final double percent;
  final double offset;
  const TextWrap({
    super.key,
    required this.child,
    this.percent = 0.6,
    this.offset = 41, // This is the width of the icon in the settings tile
  });

  @override
  Widget build(BuildContext context) {
    var width = (MediaQuery.of(context).size.width * percent) - offset;

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: width),
      child: Row(mainAxisSize: MainAxisSize.min, children: [Flexible(child: child)]),
    );
  }
}
