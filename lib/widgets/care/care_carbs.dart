import 'package:carer/nsclient/nsclient.dart';
import 'package:carer/services/settings/care_settings.dart';
import 'package:carer/services/settings/secure_settings.dart';
import 'package:carer/services/toast_service.dart';
import 'package:carer/services/update_service.dart';
import 'package:carer/widgets/common/dialogs.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

typedef OnPressedFunction = void Function();

typedef Setter = void Function(int);
typedef Getter = int Function();

class CarbsSettingsModel {
  final Getter getCarbs;
  final Setter setCarbs;

  CarbsSettingsModel(this.getCarbs, this.setCarbs);

  String get description => "${getCarbs()}g Carb";

  OnPressedFunction generateOnPressedFunction(BuildContext context) {
    var carbs = getCarbs();

    return () async {
      bool? areYouSure = await Dialogs.areYouSureDialog(context, "Confirm $description", 'Are you sure you want to $description?', "Add Carbs");

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
