import 'package:carer/models/sql/constants.dart';
import 'package:carer/nsclient/nsclient.dart';
import 'package:carer/services/settings/care_settings.dart';
import 'package:carer/services/settings/secure_settings.dart';
import 'package:carer/services/settings/ui_settings.dart';
import 'package:carer/services/themes_service.dart';
import 'package:carer/services/toast_service.dart';
import 'package:carer/services/ui/icons.dart';
import 'package:carer/services/update_service.dart';
import 'package:carer/widgets/care/care_model.dart';
import 'package:carer/widgets/common/dialogs.dart';
import 'package:carer/widgets/smarttext.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

typedef Setter = void Function(int);
typedef Getter = int Function();
typedef GetD = double Function();
typedef SetD = void Function(double);

class TempTargetSettingsModel extends CareModel {
  final String name;
  final Setter setDuration;
  final Getter getDuration;
  final GetD getHigh;
  final GetD getLow;
  final SetD setHigh;
  final SetD setLow;
  final bool isCancel;

  TempTargetSettingsModel(this.name, this.getDuration, this.setDuration, this.getLow, this.setLow, this.getHigh, this.setHigh, this.isCancel);

  @override
  IconData get icon => CarerIcons.CARE_TEMP_TARGET;

  @override
  SmartText get smartText {
    if (isCancel) {
      return SmartText(
        texts: const [
          "Cancel Target",
        ],
        styles: [
          largeStyle,
        ],
      );
    }

    var bot = getLow();
    var top = getHigh();

    Unit unit = UISettings().unit;

    if (unit.str(bot) == unit.str(top)) {
      return SmartText(texts: [
        "$name\n",
        unit.str(bot),
        unit.name,
        " for ",
        "${getDuration()}",
        "mins",
      ], styles: [
        largeStyle,
        subLargeStyle.copyWith(color: ColorSchemes.primaryColor),
        subSmallStyle,
        subSmallStyle,
        subLargeStyle.copyWith(color: ColorSchemes.primaryColor),
        subSmallStyle,
      ]);
    }

    return SmartText(texts: [
      "$name\n",
      unit.str(bot),
      " - ",
      unit.str(top),
      unit.name,
      " for ",
      "${getDuration()}",
      "mins",
    ], styles: [
      largeStyle,
      subLargeStyle.copyWith(color: ColorSchemes.primaryColor),
      subSmallStyle,
      subLargeStyle.copyWith(color: ColorSchemes.primaryColor),
      subSmallStyle,
      subSmallStyle,
      subLargeStyle.copyWith(color: ColorSchemes.primaryColor),
      subSmallStyle,
    ]);
  }

  @override
  Color get highlightColor => ColorSchemes.accentColor;

  @override
  String get description {
    if (isCancel) {
      return "Cancel Temp Target";
    }

    int duration = getDuration();

    return "${getRangeString()}\nfor $duration mins";
  }

  String getRangeString() {
    var bot = getLow();
    var top = getHigh();

    Unit unit = UISettings().unit;
    String rangeString = "${unit.str(bot)}-${unit.strWithUnit(top)}";
    if (unit.str(bot) == unit.str(top)) {
      rangeString = unit.strWithUnit(bot);
    }
    return rangeString;
  }

  @override
  OnPressedFunction generateOnPressedFunction(BuildContext context) {
    var bottom = getLow();
    var top = getHigh();
    var duration = getDuration();

    return () async {
      bool? areYouSure = await Dialogs.areYouSureDialog(context, "Confirm $description", 'Are you sure you want to $description?', "Set Temp Target");

      if (areYouSure == true) {
        var (nsURL, nsToken) = SecureSettings().nightscoutURLAndToken;
        NSClient().addTempTarget(nsURL, nsToken, bottom.toInt(), top.toInt(), duration, name).then((value) {
          if (value) {
            ToastService().showSuccess("Temp Target $description");
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
    () => 0,
    (int d) => 0,
    () => 72,
    (double bot) => 72,
    () => 180,
    (double top) => 180,
    true,
  ),
];
