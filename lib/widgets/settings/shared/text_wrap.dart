import 'package:flutter/material.dart';

class TextWrap extends StatelessWidget {
  final Widget child;
  const TextWrap({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    //TODO: in some places this is too agressive a width
    var width = (MediaQuery.of(context).size.width * .6) - 41;

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: width),
      child: Row(mainAxisSize: MainAxisSize.min, children: [Flexible(child: child)]),
    );
  }
}
