import 'package:carer/models/sql/constants.dart';
import 'package:carer/nsclient/nsclient.dart';
import 'package:carer/services/settings/care_settings.dart';
import 'package:carer/services/settings/secure_settings.dart';
import 'package:carer/services/settings/ui_settings.dart';
import 'package:carer/services/toast_service.dart';
import 'package:carer/services/ui/icons.dart';
import 'package:carer/services/update_service.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/widgets/common/dialogs.dart';
import 'package:carer/widgets/settings/shared/settings_slider.dart';
import 'package:carer/widgets/settings/shared/target_range_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_settings_ui/flutter_settings_ui.dart';
import 'package:go_router/go_router.dart';

ASignal<bool> _editing = ASignal<bool>(false, debugLabel: "CarePageEditing");

typedef Setter = void Function(int);
typedef Getter = int Function();
typedef GetD = double Function();
typedef SetD = void Function(double);

class CarbsSettingsModel {
  final Getter getCarbs;
  final Setter setCarbs;

  CarbsSettingsModel(this.getCarbs, this.setCarbs);

  String get description => "Add ${getCarbs()}g Carb";
}

class TempTargetSettingsModel {
  final String name;
  final Setter setDuration;
  final Getter getDuration;
  final GetD getHigh;
  final GetD getLow;
  final SetD setHigh;
  final SetD setLow;

  TempTargetSettingsModel(this.name, this.getDuration, this.setDuration, this.getLow, this.setLow, this.getHigh, this.setHigh);

  String get description {
    var bot = getLow();
    var top = getHigh();
    int duration = getDuration();
    Unit unit = UISettings().unit;
    String description = "Set ${unit.str(bot)}-${unit.strWithUnit(top)} for $duration minutes";
    if (unit.str(bot) == unit.str(top)) {
      description = "Set ${unit.strWithUnit(bot)} for $duration minutes";
    }
    return description;
  }
}

List<CarbsSettingsModel> allCarbs = [
  CarbsSettingsModel(
    () => CareSettings().carbs1Value,
    (int d) => CareSettings().carbs1Value = d.toInt(),
  ),
  CarbsSettingsModel(
    () => CareSettings().carbs2Value,
    (int d) => CareSettings().carbs2Value = d.toInt(),
  ),
  CarbsSettingsModel(
    () => CareSettings().carbs3Value,
    (int d) => CareSettings().carbs3Value = d.toInt(),
  ),
  CarbsSettingsModel(
    () => CareSettings().carbs4Value,
    (int d) => CareSettings().carbs4Value = d.toInt(),
  ),
];

List<TempTargetSettingsModel> allTempTargets = [
  TempTargetSettingsModel(
    "Hypo",
    () => CareSettings().tempTargetHypoDuration,
    (int d) => CareSettings().tempTargetHypoDuration = d.toInt(),
    () => CareSettings().tempTargetHypoBottom,
    (double bot) => CareSettings().tempTargetHypoBottom = bot,
    () => CareSettings().tempTargetHypoTop,
    (double top) => CareSettings().tempTargetHypoTop = top,
  ),
  TempTargetSettingsModel(
    "Activity",
    () => CareSettings().tempTargetActivityDuration,
    (int d) => CareSettings().tempTargetActivityDuration = d.toInt(),
    () => CareSettings().tempTargetActivityBottom,
    (double bot) => CareSettings().tempTargetActivityBottom = bot,
    () => CareSettings().tempTargetActivityTop,
    (double top) => CareSettings().tempTargetActivityTop = top,
  ),
  TempTargetSettingsModel(
    "Eating Soon",
    () => CareSettings().tempTargetEatingDuration,
    (int d) => CareSettings().tempTargetEatingDuration = d.toInt(),
    () => CareSettings().tempTargetEatingBottom,
    (double bot) => CareSettings().tempTargetEatingBottom = bot,
    () => CareSettings().tempTargetEatingTop,
    (double top) => CareSettings().tempTargetEatingTop = top,
  ),
];

class CarePage extends StatelessWidget {
  const CarePage({super.key});

  @override
  Widget build(BuildContext context) {
    return AWatch((context) {
      IconData actionIcon = _editing.value ? CarerIcons.BAR_DONE_CARE : CarerIcons.BAR_EDIT_CARE;

      return Scaffold(
        appBar: AppBar(
          title: const Text('Care'),
          actions: [
            IconButton(
              icon: Icon(actionIcon),
              onPressed: () {
                _editing.value = !_editing.peek();
              },
            ),
          ],
        ),
        body: SettingsList(
          sections: [
                SettingsSection(
                  title: const Text('Carbs'),
                  tiles: carbsActionTiles(),
                )
              ] +
              tempTargetSections(),
        ),
      );
    }, debugLabel: "CarePage");
  }

  List<SettingsTile> carbsActionTiles() {
    if (_editing.value) {
      return allCarbs
          .map(
            (e) => SettingsTile(
              title: SettingsSlider(
                title: e.description,
                getValue: () => e.getCarbs().toDouble(),
                setValue: (double val) => e.setCarbs(val.toInt()),
                getStr: (double val) => val.toInt().toString(),
                minRange: CareSettings().MIN_CARBS.toDouble(),
                maxRange: CareSettings().MAX_CARBS.toDouble(),
                divisions: CareSettings().MAX_CARBS - CareSettings().MIN_CARBS,
                dependencies: const [],
              ),
            ),
          )
          .toList();
    }
    return allCarbs.map((e) => carbsActionTile(e)).toList();
  }

  List<SettingsSection> getTempTargetEdit(TempTargetSettingsModel e) {
    return [
      SettingsSection(
        title: Text(e.name),
        tiles: [
          SettingsTile(
            title: Text(e.name),
            description: Text(e.description),
            descriptionInlineIos: true,
          ),
          SettingsTile(
            title: TargetRangeSlider(
              title: "Range",
              getLow: () => e.getLow(),
              getHigh: () => e.getHigh(),
              setLow: (double val) => e.setLow(val),
              setHigh: (double val) => e.setHigh(val),
              getStr: (double val) => UISettings().unit.str(val),
              fromStr: (String str) => UISettings().unit.fromStr(str),
              minRange: 72,
              maxRange: 180,
              dependencies: const [],
            ),
          ),
          SettingsTile(
            title: SettingsSlider(
              title: "Duration",
              getValue: () => e.getDuration().toDouble(),
              setValue: (double val) => e.setDuration(val.toInt()),
              minRange: 1,
              maxRange: 120,
              divisions: 24,
              dependencies: const [],
            ),
          ),
        ],
      )
    ];
  }

  List<SettingsSection> tempTargetSections() {
    if (_editing.value) {
      return getTempTargetEdit(allTempTargets[0]) + getTempTargetEdit(allTempTargets[1]) + getTempTargetEdit(allTempTargets[2]);
    }

    return [
      SettingsSection(
        title: const Text('Temp Target'),
        tiles: allTempTargets.map((e) => tempTargetActionTile(e)).toList(),
      )
    ];
  }

  SettingsTile tempTargetActionTile(TempTargetSettingsModel e) {
    var name = e.name;
    var bottom = e.getLow();
    var top = e.getHigh();
    var duration = e.getDuration();

    return SettingsTile.navigation(
      title: Text(name),
      description: Text(e.description),
      descriptionInlineIos: true,
      onPressed: (context) async {
        bool? areYouSure =
            await Dialogs.areYouSureDialog(context, "Confirm ${e.description}", 'Are you sure you want to ${e.description}?', "Set Temp Target");

        if (areYouSure == true) {
          var (nsURL, nsToken) = SecureSettings().nightscoutURLAndToken;
          NSClient().addTempTarget(nsURL, nsToken, bottom.toInt(), top.toInt(), duration, name).then((value) {
            if (value) {
              ToastService().showSuccess("Temp Target ${e.description}");
              UpdateService().nsTreatmentUpdater.addExternalReason("Added Temp Target");
            } else {
              ToastService().showError("Failed to set TempTarget");
            }
          });

          if (context.mounted) {
            GoRouter.of(context).go("/display", extra: {'from': '/care'});
          }
        }
      },
    );
  }

  SettingsTile carbsActionTile(CarbsSettingsModel e) {
    int carbs = e.getCarbs();
    return SettingsTile.navigation(
      title: Text('Add ${carbs}g Carb'),
      onPressed: (context) async {
        bool? areYouSure =
            await Dialogs.areYouSureDialog(context, "Confirm ${e.description}", 'Are you sure you want to ${e.description}?', "Add Carbs");

        if (areYouSure == true) {
          var (nsURL, nsToken) = SecureSettings().nightscoutURLAndToken;
          NSClient().addCarbs(nsURL, nsToken, carbs).then((value) {
            if (value) {
              ToastService().showSuccess("${carbs}g carbs added");
              UpdateService().nsTreatmentUpdater.addExternalReason("Added Carbs");
            } else {
              ToastService().showError("Failed to add ${carbs}g carbs");
            }
          });
          if (context.mounted) {
            GoRouter.of(context).go("/display", extra: {'from': '/care'});
          }
        }
      },
    );
  }
}
