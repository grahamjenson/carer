import 'package:carer/services/settings/care_settings.dart';
import 'package:carer/services/settings/ui_settings.dart';
import 'package:carer/services/themes_service.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/widgets/care/care_carbs.dart';
import 'package:carer/widgets/care/care_profiles.dart';
import 'package:carer/widgets/care/care_temp_targets.dart';
import 'package:carer/widgets/settings/shared/plus_minus_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_settings_ui/flutter_settings_ui.dart';
import 'package:go_router/go_router.dart';

class CareEditPage extends StatelessWidget with ThemeMixin {
  const CareEditPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AWatch(
      (context) {
        var sections = SettingsList(sections: [
          SettingsSection(
            title: const Text('Edit Carbs Settings'),
            tiles: allCarbs.map((e) => carbsEdit(context, e)).toList(),
          ),
          SettingsSection(
            title: const Text('Edit Temp Target'),
            tiles: allTempTargets.where((e) => !e.isCancel).map((e) => tempTargetEdit(context, e)).toList(),
          ),
          SettingsSection(
            title: const Text('Edit Profile Switches'),
            tiles: allProfileSwitches.map((e) => profileEdit(context, e)).toList(),
          )
        ]);
        return Scaffold(
          appBar: AppBar(
            title: const Text('Care'),
            actions: [getDoneButton(context)],
          ),
          body: sections,
        );
      },
      debugLabel: "CareEditPage",
      dependencies: [UISettings().unitSignal, UISettings().orientationSignal] + CareSettings().allSignals(),
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
    Widget trailing = SizedBox(
      width: 60,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          PlusMinusText(
            getStr: (double val) => "${val.toInt()}",
            fromStr: (String str) => double.tryParse(str),
            getValue: () => e.getCarbs().toDouble(),
            setValue: (double val) => e.setCarbs(val.toInt()),
            dependencies: [e.carbsSignal],
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

  SettingsTile profileEdit(BuildContext context, ProfileSettingsModel e) {
    var dimStyle = TextStyle(
      color: onBackgroundColor(context).dim,
      fontSize: 10,
    );

    Widget? description = Text(
      e.description,
      style: dimStyle,
    );

    Widget trailing = SizedBox(
      width: 100,
      child: Row(
        children: [
          Column(children: [
            Text("Percent ", style: dimStyle),
            PlusMinusText(
              getStr: (double val) => "${val.toInt()}",
              fromStr: (String str) => double.tryParse(str),
              getValue: () => e.getPercent().toDouble(),
              setValue: (double val) => e.setPercent(val.toInt()),
              dependencies: [e.percentSignal],
            ),
          ]),
          const Spacer(),
          Column(
            children: [
              Text("Time ", style: dimStyle),
              PlusMinusText(
                getStr: (double val) => "${val.toInt()}",
                fromStr: (String str) => double.tryParse(str),
                getValue: () => e.getDuration().toDouble(),
                setValue: (double val) => e.setDuration(val.toInt()),
                dependencies: [e.durationSignal],
              ),
            ],
          ),
        ],
      ),
    );

    var initSelect = e.getName();
    var remoteNames = ["Profilewqeasfasf", "Profile2"];

    var remoteContainsSelection = false;
    if (remoteNames.contains(initSelect)) {
      remoteContainsSelection = true;
    }

    var selectionItems = [const DropdownMenuEntry(value: "", label: "NONE")];
    selectionItems.addAll(remoteNames.map((name) {
      return DropdownMenuEntry(value: name, label: name);
    }).toList());

    if (!remoteContainsSelection) {
      selectionItems.add(DropdownMenuEntry(value: initSelect, label: initSelect, enabled: false));
    }

    return SettingsTile(
      title: DropdownMenu(
        width: 145,
        menuStyle: const MenuStyle(
          padding: WidgetStatePropertyAll(EdgeInsets.zero),
          visualDensity: VisualDensity(horizontal: -4, vertical: -4),
        ),
        inputDecorationTheme: InputDecorationTheme(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
          constraints: BoxConstraints.tight(const Size.fromHeight(30)),
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.zero,
          ),
        ),
        textStyle: const TextStyle(
          fontSize: 14,
        ),
        dropdownMenuEntries: selectionItems,
        initialSelection: initSelect,
        onSelected: (value) {
          if (value != null) {
            e.setName(value);
          }
        },
      ),
      descriptionInlineIos: true,
      description: description,
      trailing: trailing,
    );
  }
}
