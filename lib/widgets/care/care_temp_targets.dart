import 'package:carer/models/sql/constants.dart';
import 'package:carer/nsclient/nsclient.dart';
import 'package:carer/services/settings/care_settings.dart';
import 'package:carer/services/settings/secure_settings.dart';
import 'package:carer/services/settings/ui_settings.dart';
import 'package:carer/services/themes_service.dart';
import 'package:carer/services/toast_service.dart';
import 'package:carer/services/update_service.dart';
import 'package:carer/widgets/common/dialogs.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

typedef OnPressedFunction = void Function();

typedef Setter = void Function(int);
typedef Getter = int Function();
typedef GetD = double Function();
typedef SetD = void Function(double);

class TempTargetSettingsModel {
  final String name;
  final Setter setDuration;
  final Getter getDuration;
  final GetD getHigh;
  final GetD getLow;
  final SetD setHigh;
  final SetD setLow;
  final bool isCancel;

  TempTargetSettingsModel(this.name, this.getDuration, this.setDuration, this.getLow, this.setLow, this.getHigh, this.setHigh, this.isCancel);

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

List<TempTargetSettingsModel> allTempTargets = [
  TempTargetSettingsModel(
    "Hypo",
    () => CareSettings().tempTargetHypoDuration,
    (int d) => CareSettings().tempTargetHypoDuration = d.toInt(),
    () => CareSettings().tempTargetHypoBottom,
    (double bot) => CareSettings().tempTargetHypoBottom = bot,
    () => CareSettings().tempTargetHypoTop,
    (double top) => CareSettings().tempTargetHypoTop = top,
    false,
  ),
  TempTargetSettingsModel(
    "Activity",
    () => CareSettings().tempTargetActivityDuration,
    (int d) => CareSettings().tempTargetActivityDuration = d.toInt(),
    () => CareSettings().tempTargetActivityBottom,
    (double bot) => CareSettings().tempTargetActivityBottom = bot,
    () => CareSettings().tempTargetActivityTop,
    (double top) => CareSettings().tempTargetActivityTop = top,
    false,
  ),
  TempTargetSettingsModel(
    "Eating Soon",
    () => CareSettings().tempTargetEatingDuration,
    (int d) => CareSettings().tempTargetEatingDuration = d.toInt(),
    () => CareSettings().tempTargetEatingBottom,
    (double bot) => CareSettings().tempTargetEatingBottom = bot,
    () => CareSettings().tempTargetEatingTop,
    (double top) => CareSettings().tempTargetEatingTop = top,
    false,
  ),
  TempTargetSettingsModel(
    "Cancel",
    () => -1,
    (int d) => -1,
    () => -1,
    (double bot) => -1,
    () => -1,
    (double top) => -1,
    true,
  ),
];

////
// TempTargets
////

// SHARED

class CareTempTargets extends StatelessWidget {
  const CareTempTargets({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.blue,
      height: 200,
      width: 200,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Flexible(
            flex: 1,
            child: Text("Temp Targets"),
          ),
          Flexible(
            flex: 3,
            child: GridView.count(
              crossAxisCount: 2,
              children: allTempTargets.map((e) => tempTargetSections(context, e)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget tempTargetSections(BuildContext context, TempTargetSettingsModel e) {
    TextStyle textStyle = const TextStyle(fontSize: 50, color: ColorSchemes.primaryColor);

    var buttonStyle = ElevatedButton.styleFrom(
      textStyle: const TextStyle(fontSize: 50, color: ColorSchemes.primaryColor),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8), // Square shape
        side: const BorderSide(
          color: ColorSchemes.primaryColor,
          width: 2,
        ), // Border color and width
      ),
      minimumSize: const Size(100, 100), // Square size (width and height)
      padding: const EdgeInsets.all(10), // Remove default padding
    );

    if (e.isCancel) {
      return ElevatedButton(onPressed: () => print("TODO"), child: const Text("Cancel"));
    }

    Widget ret = ElevatedButton(
      onPressed: generateOnPressed(context, e),
      style: buttonStyle,
      child: Text("Set ${e.name} ${e.description}"),
    );

    return SizedBox(
      width: 100,
      height: 100,
      child: ret,
    );
  }

  OnPressedFunction generateOnPressed(BuildContext context, TempTargetSettingsModel e) {
    var name = e.name;
    var bottom = e.getLow();
    var top = e.getHigh();
    var duration = e.getDuration();

    return () async {
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
  }
}
