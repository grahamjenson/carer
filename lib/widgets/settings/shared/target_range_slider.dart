import 'package:carer/services/themes_service.dart';
import 'package:carer/services/ui/icons.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/widgets/settings/shared/plus_minus_text.dart';
import 'package:flutter/material.dart';

typedef Setter = void Function(double);
typedef Getter = double Function();

typedef GetStr = String Function(double);
typedef FromStr = double? Function(String);

class TargetRangeSlider extends StatelessWidget with ThemeMixin {
  final String title;
  final double minRange;
  final double maxRange;
  final Getter getLow;
  final Getter getHigh;

  final GetStr? getStr;
  final FromStr? fromStr;
  final Setter setLow;
  final Setter setHigh;
  final List<ASignal> dependencies;

  final bool signed;
  const TargetRangeSlider({
    super.key,
    required this.title,
    required this.getLow,
    required this.getHigh,
    this.getStr,
    this.fromStr,
    required this.setLow,
    required this.setHigh,
    required this.minRange,
    required this.maxRange,
    required this.dependencies,
    this.signed = false,
  });

  @override
  Widget build(BuildContext context) {
    return AWatch(
      (context) {
        var low = getLow();
        var high = getHigh();

        return Row(children: [
          Expanded(flex: 2, child: Text(title)),
          PlusMinusText(
            getStr: getStr ?? (double val) => val.toString(),
            fromStr: fromStr ?? (String str) => double.tryParse(str),
            getValue: getLow,
            setValue: setLow,
            dependencies: dependencies,
            signed: signed,
          ),
          Icon(CarerIcons.SETTINGS_RANGE_ICON, size: 20, color: Theme.of(context).colorScheme.primary),
          PlusMinusText(
            getStr: getStr ?? (double val) => val.toString(),
            fromStr: fromStr ?? (String str) => double.tryParse(str),
            getValue: getHigh,
            setValue: setHigh,
            dependencies: dependencies,
            signed: signed,
          ),
        ]);
      },
      debugLabel: "TargetRangeSlider",
      dependencies: dependencies,
    );
  }
}
