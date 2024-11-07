import 'package:carer/services/themes_service.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/widgets/settings/shared/plus_minus_text.dart';
import 'package:flutter/material.dart';

typedef Setter = void Function(double);
typedef Getter = double Function();
typedef GetStr = String Function(double);

class SettingsSlider extends StatelessWidget with ThemeMixin {
  final String title;
  final double minRange;
  final double maxRange;
  final int divisions;

  final Getter getValue;
  final Setter setValue;

  final Getter getDiff;
  final GetStr getStr;

  final List<ASignal> dependencies;

  const SettingsSlider({
    super.key,
    required this.title,
    required this.getValue,
    required this.getStr,
    required this.getDiff,
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
        var diff = getDiff();
        var value = getValue();

        return Row(children: [
          Expanded(flex: 2, child: Text(title)),
          PlusMinusText(
            getText: getStr,
            getValue: getValue,
            diff: diff,
            setValue: setValue,
            dependencies: dependencies,
          ),
          Expanded(
              flex: 5,
              child: Container(
                  alignment: Alignment.center,
                  height: 20,
                  child: Slider(
                    value: value,
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
