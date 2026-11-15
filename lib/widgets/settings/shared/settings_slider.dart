import 'package:carer/services/themes_service.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/widgets/settings/shared/plus_minus_text.dart';
import 'package:flutter/material.dart';

typedef Setter = void Function(double);
typedef Getter = double Function();
typedef GetStr = String Function(double);
typedef FromStr = double? Function(String);

class SettingsSlider extends StatelessWidget with ThemeMixin {
  final String title;
  final double minRange;
  final double maxRange;
  final int divisions;

  final Getter getValue;
  final Setter setValue;

  final FromStr? fromStr;
  final GetStr? getStr;

  final List<ASignal> dependencies;

  const SettingsSlider({
    super.key,
    required this.title,
    required this.getValue,
    this.getStr,
    this.fromStr,
    required this.setValue,
    required this.minRange,
    required this.maxRange,
    required this.divisions,
    required this.dependencies,
  });

  @override
  Widget build(BuildContext context) {
    return AWatch(
      (context) {
        var value = getValue();

        return Row(children: [
          Expanded(flex: 4, child: Text(title)),
          PlusMinusText(
            getStr: getStr ?? (double val) => val.toString(),
            fromStr: fromStr ?? (String str) => double.tryParse(str),
            getValue: getValue,
            setValue: setValue,
            dependencies: dependencies,
          ),
          Expanded(
              flex: 11,
              child: Container(
                  alignment: Alignment.center,
                  height: 20,
                  child: Slider(
                    value: value,
                    activeColor: ColorSchemes.primaryColor,
                    divisions: 100,
                    min: minRange,
                    max: maxRange,
                    onChanged: (double value) {
                      setValue(value);
                    },
                  ))),
        ]);
      },
      debugLabel: "SettingsSlider",
      dependencies: dependencies,
    );
  }
}
