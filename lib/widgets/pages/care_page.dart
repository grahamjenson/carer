import 'package:animations/animations.dart';
import 'package:carer/models/sql/constants.dart';
import 'package:carer/nsclient/nsclient.dart';
import 'package:carer/services/settings/care_settings.dart';
import 'package:carer/services/settings/secure_settings.dart';
import 'package:carer/services/settings/ui_settings.dart';
import 'package:carer/services/themes_service.dart';
import 'package:carer/services/toast_service.dart';
import 'package:carer/services/update_service.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/widgets/common/dialogs.dart';
import 'package:carer/widgets/settings/shared/plus_minus_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_settings_ui/flutter_settings_ui.dart';
import 'package:go_router/go_router.dart';

typedef Setter = void Function(int);
typedef Getter = int Function();
typedef GetD = double Function();
typedef SetD = void Function(double);

class CarbsSettingsModel {
  final Getter getCarbs;
  final Setter setCarbs;

  CarbsSettingsModel(this.getCarbs, this.setCarbs);

  String get description => "${getCarbs()}g Carb";
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
    String description = "${unit.str(bot)}-${unit.strWithUnit(top)}\nfor $duration mins";
    if (unit.str(bot) == unit.str(top)) {
      description = "${unit.strWithUnit(bot)}\nfor $duration mins";
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

class CarePage extends StatefulWidget {
  const CarePage({super.key});

  @override
  State<CarePage> createState() => _CarePageState();
}

class _CarePageState extends State<CarePage> with ThemeMixin {
  bool _editing = false;

  @override
  Widget build(BuildContext context) {
    var sections = SettingsList(sections: [
      SettingsSection(
        title: const Text('Add Carbs'),
        tiles: allCarbs.map((e) => carbsActionTile(context, e)).toList(),
      ),
      SettingsSection(
        title: const Text('Set Temp Target'),
        tiles: allTempTargets.map((e) => tempTargetSections(context, e)).toList(),
      )
    ]);
    return AWatch(
      (context) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Care'),
            actions: [getActionButton(context)],
          ),
          body: sections,
        );
      },
      debugLabel: "CarePageWidget",
    );
  }

  Widget getActionButton(BuildContext context) {
    Widget actionText = _editing
        ? Text(
            "Done",
            style: TextStyle(color: accentColor(context), fontSize: 16),
          )
        : Text(
            "Edit",
            style: TextStyle(color: accentColor(context), fontSize: 16),
          );

    return SizedBox(
      width: 100,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor(context).dim,
        ),
        child: actionText,
        onPressed: () {
          setState(() {
            _editing = !_editing;
          });
        },
      ),
    );
  }

  @override
  void dispose() {
    _editing = false;
    super.dispose();
  }

  ////
  // CARBS
  ////

  SettingsTile carbsActionTile(BuildContext context, CarbsSettingsModel e) {
    var carbs = e.getCarbs();

    Function(BuildContext context)? onPressed = (context) async {
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
    };

    Widget trailing = SizedBox(key: ValueKey("care_add_carbs_$carbs"), width: 60, child: callToAction(context, "Add"));
    if (_editing) {
      trailing = SizedBox(
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
      onPressed = null;
    }

    return SettingsTile(
      title: Text(
        e.description,
        softWrap: false,
      ),
      trailing: animations(trailing),
      onPressed: onPressed,
    );
  }

  ////
  // TempTargets
  ////

  SettingsTile tempTargetSections(BuildContext context, TempTargetSettingsModel e) {
    var name = e.name;
    var bottom = e.getLow();
    var top = e.getHigh();
    var duration = e.getDuration();

    Function(BuildContext context)? onPressed = (context) async {
      bool? areYouSure =
          await Dialogs.areYouSureDialog(context, "Confirm ${e.description}", 'Are you sure you want to ${e.description}?', "Set Temp Target");

      if (areYouSure == true) {
        var (nsURL, nsToken) = SecureSettings().nightscoutURLAndToken;
        NSClient().addTempTarget(nsURL, nsToken, bottom.toInt(), top.toInt(), duration, name).then((value) {
          if (value) {
            ToastService().showSuccess("Temp Target ${e.description}");
            UpdateService().nsTreatmentUpdater.addExternalReason("Added Temp Target");
          } else {
            ToastService().showError("Failed to set Temp Target");
          }
        });

        if (context.mounted) {
          GoRouter.of(context).go("/display", extra: {'from': '/care'});
        }
      }
    };

    Widget trailing = SizedBox(
      width: 170,
      key: ValueKey("care_add_temptarget_$name"),
      child: callToAction(context, "Set"),
    );

    var dimStyle = TextStyle(
      color: onBackgroundColor(context).dim,
      fontSize: 10,
    );

    Widget? description = Text(
      e.description,
      style: dimStyle,
    );

    if (_editing) {
      onPressed = null;

      trailing = SizedBox(
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
    }

    return SettingsTile(
      title: Text(
        name,
      ),
      descriptionInlineIos: true,
      description: description,
      trailing: animations(trailing),
      onPressed: onPressed,
    );
  }

  // SHARED

  Widget animations(Widget child) {
    return PageTransitionSwitcher(
      duration: const Duration(milliseconds: 200),
      child: child,
      transitionBuilder: (child, animation, secondaryAnimation) {
        var offset = const Offset(1.5, 0);
        var soffset = const Offset(1.5, 0);
        if (_editing) {
          offset = const Offset(1.5, 0);
          soffset = const Offset(1.5, 0);
        }
        var slideAnimation = animation.drive(
          Tween<Offset>(
            begin: offset,
            end: Offset.zero,
          ).chain(
            CurveTween(curve: Curves.easeIn),
          ),
        );

        var slideSecondaryAnimation = secondaryAnimation.drive(
          Tween<Offset>(
            begin: Offset.zero,
            end: soffset,
          ).chain(
            CurveTween(curve: Curves.easeIn),
          ),
        );

        return SlideTransition(
          position: slideAnimation,
          child: SlideTransition(position: slideSecondaryAnimation, child: child),
        );
      },
    );
  }

  Widget callToAction(BuildContext context, String action) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        height: 30,
        width: 60,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: backgroundColor(context),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Center(
          child: InkWell(
            onTap: null,
            child: Text(action, style: TextStyle(color: accentColor(context), fontSize: 16)),
          ),
        ),
      ),
    );
  }
}
