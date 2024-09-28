import 'package:flutter/material.dart';

class SmartText extends StatelessWidget {
  final List<String> texts;
  final List<TextStyle?> styles;
  final TextAlign textAlign;
  const SmartText({super.key, required this.texts, required this.styles, this.textAlign = TextAlign.start})
      : assert(texts.length == styles.length && texts.length > 0);

  @override
  Widget build(BuildContext context) {
    List<TextSpan> spans = [];
    for (int i = 0; i < texts.length; i++) {
      spans.add(TextSpan(text: texts[i], style: styles[i]));
    }
    return RichText(
      text: TextSpan(children: spans, style: DefaultTextStyle.of(context).style),
    );
  }
}
