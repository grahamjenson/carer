import 'package:carer/services/themes_service.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/widgets/settings/shared/target_range_slider.dart';
import 'package:flutter/material.dart';
import 'package:unicons/unicons.dart';

class PlusMinusText extends StatelessWidget with ThemeMixin {
  final GetStr getText;
  final Getter getValue;
  final double diff;
  final Setter setValue;
  final List<ASignal> dependencies;

  const PlusMinusText({
    super.key,
    required this.getText,
    required this.getValue,
    required this.diff,
    required this.setValue,
    required this.dependencies,
  });

  @override
  Widget build(BuildContext context) {
    return AWatch((context) {
      double value = getValue();
      String text = getText(value);

      var constraints = const BoxConstraints(
        minWidth: 20,
        minHeight: 20,
        maxHeight: 20,
        maxWidth: 20,
      );
      var style = ButtonStyle(
        shape: WidgetStateProperty.all<RoundedRectangleBorder>(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        backgroundColor: WidgetStateProperty.all(
          primaryColor(context),
        ),
      );

      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 14,
            height: 14,
            margin: const EdgeInsets.only(right: 2),
            padding: const EdgeInsets.all(0),
            alignment: Alignment.centerRight,
            child: IconButton(
              padding: const EdgeInsets.all(0),
              constraints: constraints,
              style: style,
              onPressed: () => setValue(value - diff),
              icon: const Icon(UniconsLine.minus, size: 13, color: Colors.black),
            ),
          ),
          Text(text, style: const TextStyle(fontSize: 14, height: 0.8)),
          Container(
            width: 14,
            height: 14,
            margin: const EdgeInsets.only(left: 2),
            padding: const EdgeInsets.all(0),
            alignment: Alignment.centerLeft,
            child: IconButton(
              padding: const EdgeInsets.all(0),
              constraints: constraints,
              style: style,
              onPressed: () => setValue(value + diff),
              icon: const Icon(UniconsLine.plus, size: 13, color: Colors.black),
            ),
          ),
        ],
      );
    }, debugLabel: "PlusMinusText", dependencies: dependencies);
  }
}
