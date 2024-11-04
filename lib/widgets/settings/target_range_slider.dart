import 'package:carer/models/sql/constants.dart';
import 'package:carer/services/settings/ui_settings.dart';
import 'package:carer/services/themes_service.dart';
import 'package:carer/utils/futures.dart';
import 'package:flutter/material.dart';
import 'package:unicons/unicons.dart';

typedef Setter = void Function(double);
typedef Getter = double Function();

class TargetRangeSlider extends StatelessWidget with ThemeMixin {
  final String title;
  final double minRange;
  final double maxRange;
  final Getter getLow;
  final Getter getHigh;
  final Setter setLow;
  final Setter setHigh;
  final List<ASignal> dependencies;

  const TargetRangeSlider({
    super.key,
    required this.title,
    required this.getLow,
    required this.getHigh,
    required this.setLow,
    required this.setHigh,
    required this.minRange,
    required this.maxRange,
    required this.dependencies,
  });

  @override
  Widget build(BuildContext context) {
    return AWatch(
      (context) {
        var unit = UISettings().unit;
        double diff = 1;
        if (unit == Unit.mmol) {
          diff = MGtoMMOL / 10;
        }
        var low = getLow();
        var high = getHigh();
        var lowText = unit.str(low);
        var highText = unit.str(high);

        return Row(children: [
          Expanded(flex: 2, child: Text(title)),
          getTextPlusMinus(context, lowText, low, diff, setLow),
          Expanded(
              flex: 5,
              child: Container(
                  alignment: Alignment.center,
                  height: 20,
                  child: RangeSlider(
                    values: RangeValues(low, high),
                    divisions: 230,
                    min: minRange,
                    max: maxRange,
                    onChanged: (RangeValues vals) {
                      setLow(vals.start.toDouble());
                      setHigh(vals.end.toDouble());
                    },
                  ))),
          getTextPlusMinus(context, highText, high, diff, setHigh),
        ]);
      },
      debugLabel: "TargetRangeSlider",
      dependencies: dependencies,
    );
  }

  Widget getTextPlusMinus(BuildContext context, String text, double value, double diff, Setter setValue) {
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
  }
}
