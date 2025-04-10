import 'package:carer/services/settings/ui_settings.dart';
import 'package:carer/services/themes_service.dart';
import 'package:carer/widgets/care/care_carbs.dart';
import 'package:carer/widgets/care/care_temp_targets.dart';
import 'package:carer/widgets/settings/shared/plus_minus_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_settings_ui/flutter_settings_ui.dart';
import 'package:go_router/go_router.dart';

class CareEditPage extends StatelessWidget with ThemeMixin {
  const CareEditPage({super.key});

  @override
  Widget build(BuildContext context) {
    var sections = SettingsList(sections: [
      SettingsSection(
        title: const Text('Edit Carbs Settings'),
        tiles: allCarbs.map((e) => carbsEdit(context, e)).toList(),
      ),
      SettingsSection(
        title: const Text('Edit Temp Target'),
        tiles: allTempTargets.map((e) => tempTargetEdit(context, e)).toList(),
      )
    ]);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Care'),
        actions: [getDoneButton(context)],
      ),
      body: sections,
    );
  }

  Widget getDoneButton(BuildContext context) {
    return SizedBox(
      width: 100,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor(context).dim,
        ),
        child: Text(
          "Done",
          style: TextStyle(color: accentColor(context), fontSize: 16),
        ),
        onPressed: () {
          GoRouter.of(context).go("/care");
        },
      ),
    );
  }

  SettingsTile tempTargetEdit(BuildContext context, TempTargetSettingsModel e) {
    var name = e.name;

    var dimStyle = TextStyle(
      color: onBackgroundColor(context).dim,
      fontSize: 10,
    );

    Widget? description = Text(
      e.description,
      style: dimStyle,
    );

    Widget trailing = SizedBox(
        key: ValueKey("care_edit_temptarget_$name"),
        width: 170,
        child: Row(
          children: [
            Column(children: [
              Text("Target ", style: dimStyle),
              Row(children: [
                PlusMinusText(
                  getStr: (double val) => UISettings().unit.str(val),
                  fromStr: (String str) => UISettings().unit.fromStr(str),
                  getValue: () => e.getLow(),
                  setValue: (double val) => e.setLow(val),
                  dependencies: const [],
                ),
                Text("-", style: dimStyle),
                PlusMinusText(
                  getStr: (double val) => UISettings().unit.str(val),
                  fromStr: (String str) => UISettings().unit.fromStr(str),
                  getValue: () => e.getHigh(),
                  setValue: (double val) => e.setHigh(val),
                  dependencies: const [],
                ),
              ]),
            ]),
            const Spacer(),
            Column(
              children: [
                Text("Time ", style: dimStyle),
                PlusMinusText(
                  getStr: (double val) => val.toInt().toString(),
                  fromStr: (String str) => double.tryParse(str),
                  getValue: () => e.getDuration().toDouble(),
                  setValue: (double val) => e.setDuration(val.toInt()),
                  dependencies: const [],
                ),
              ],
            ),
          ],
        ));

    return SettingsTile(
      title: Text(
        name,
      ),
      descriptionInlineIos: true,
      description: description,
      trailing: trailing,
    );
  }

  SettingsTile carbsEdit(BuildContext context, CarbsSettingsModel e) {
    var carbs = e.getCarbs();

    Widget trailing = SizedBox(
      key: ValueKey("care_edit_carbs_$carbs"),
      width: 60,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          PlusMinusText(
            getStr: (double val) => "${val.toInt()}",
            fromStr: (String str) => double.tryParse(str),
            getValue: () => e.getCarbs().toDouble(),
            setValue: (double val) => e.setCarbs(val.toInt()),
            dependencies: const [],
          ),
        ],
      ),
    );

    return SettingsTile(
      title: Text(
        e.description,
        softWrap: false,
      ),
      trailing: trailing,
    );
  }
}
