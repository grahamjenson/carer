import 'package:carer/nsclient/nsclient.dart';
import 'package:carer/services/settings/care_settings.dart';
import 'package:carer/services/settings/secure_settings.dart';
import 'package:carer/services/themes_service.dart';
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

class CareCarbs extends StatelessWidget {
  const CareCarbs({super.key});

  @override
  Widget build(BuildContext context) {
    TextStyle textStyle = const TextStyle(fontSize: 50, color: ColorSchemes.primaryColor);

    return Container(
      color: Colors.green,
      height: 200,
      width: 200,
      child: Column(
        children: [
          const Flexible(child: Text("Carbs")),
          Expanded(
            flex: 10,
            child: GridView.count(
              crossAxisCount: 2,
              children: allCarbs.map((e) => carbsActionTile(context, e)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget carbsActionTile(BuildContext context, CarbsSettingsModel e) {
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

    Widget ret = ElevatedButton(
      style: buttonStyle,
      onPressed: generateOnPressedFunction(context, e),
      child: Text("Add ${e.description}"),
    );

    return SizedBox(
      width: 100,
      height: 100,
      child: ret,
    );
  }

  OnPressedFunction generateOnPressedFunction(BuildContext context, CarbsSettingsModel e) {
    var carbs = e.getCarbs();

    return () async {
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
  }
}
