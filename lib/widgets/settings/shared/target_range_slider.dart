import 'package:carer/services/themes_service.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/widgets/settings/shared/plus_minus_text.dart';
import 'package:flutter/material.dart';

typedef Setter = void Function(double);
typedef Getter = double Function();
typedef GetStr = String Function(double);

class TargetRangeSlider extends StatelessWidget with ThemeMixin {
  final String title;
  final double minRange;
  final double maxRange;
  final Getter getLow;
  final Getter getHigh;
  final Getter getDiff;
  final GetStr getStr;
  final Setter setLow;
  final Setter setHigh;
  final List<ASignal> dependencies;

  const TargetRangeSlider({
    super.key,
    required this.title,
    required this.getLow,
    required this.getHigh,
    required this.getStr,
    required this.getDiff,
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
        var diff = getDiff();
        var low = getLow();
        var high = getHigh();

        return Row(children: [
          Expanded(flex: 2, child: Text(title)),
          PlusMinusText(
            getText: getStr,
            getValue: getLow,
            diff: diff,
            setValue: setLow,
            dependencies: dependencies,
          ),
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
          PlusMinusText(
            getText: getStr,
            getValue: getHigh,
            diff: diff,
            setValue: setHigh,
            dependencies: dependencies,
          ),
        ]);
      },
      debugLabel: "TargetRangeSlider",
      dependencies: dependencies,
    );
  }
}
