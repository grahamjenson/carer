import 'package:flutter/material.dart';

class SmartText extends StatelessWidget {
  final List<String> texts;
  final List<TextStyle?> styles;
  final TextAlign textAlign;
  const SmartText({super.key, required this.texts, required this.styles, this.textAlign = TextAlign.start})
      : assert(texts.length == styles.length && texts.length > 0);

  @override
  Widget build(BuildContext context) {
    var childrenTextSpans = <TextSpan>[for (var i = 0; i < texts.length; i++) TextSpan(text: texts[i], style: styles[i])];

    return RichText(
      textAlign: textAlign,
      overflow: TextOverflow.visible,
      softWrap: false,
      text: TextSpan(children: childrenTextSpans),
    );
  }
}
