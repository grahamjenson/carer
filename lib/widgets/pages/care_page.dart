import 'package:carer/models/sql/constants.dart';
import 'package:carer/nsclient/nsclient.dart';
import 'package:carer/services/settings/secure_settings.dart';
import 'package:carer/services/settings/ui_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_settings_ui/flutter_settings_ui.dart';

class CarePage extends StatelessWidget {
  const CarePage({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Care'),
        ),
        body: SettingsList(
          sections: [
            SettingsSection(
              title: const Text('Carbs'),
              tiles: [
                carbsTile(1),
                carbsTile(5),
                carbsTile(10),
                carbsTile(15),
              ],
            ),
            SettingsSection(
              title: const Text('Temp Target'),
              tiles: [
                ttTile("Hypo", 145, 145, 30),
                ttTile("Activity", 126, 145, 30),
                ttTile("Eating Soon", 90, 90, 30),
              ],
            ),
          ],
        ),
      ),
    );
  }

  SettingsTile ttTile(String name, int bottom, int top, int duration) {
    Unit unit = UISettings().unit;
    String description = "Set ${unit.str(bottom)}-${unit.strWithUnit(top)} for $duration minutes";
    if (unit.str(bottom) == unit.str(top)) {
      description = "Set ${unit.str(bottom)} for $duration minutes";
    }
    return SettingsTile.navigation(
      title: Text(name),
      description: Text(description),
      descriptionInlineIos: true,
      onPressed: (context) async {
        bool? areYouSure = await areYouSureDialog(context, 'Are you sure you want to $description?');

        if (areYouSure != null && areYouSure) {
          var (nsURL, nsToken) = SecureSettings().nightscoutURLAndToken;
          NSClient().addTempTarget(nsURL, nsToken, bottom, top, duration, name);
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
    );
  }

  SettingsTile carbsTile(int carbs) {
    return SettingsTile.navigation(
      title: Text('Add $carbs Carb'),
      onPressed: (context) async {
        bool? areYouSure = await areYouSureDialog(context, 'Are you sure you want to add $carbs carbs?');

        if (areYouSure != null && areYouSure) {
          var (nsURL, nsToken) = SecureSettings().nightscoutURLAndToken;
          NSClient().addCarbs(nsURL, nsToken, carbs);
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
    );
  }

  Future<bool?> areYouSureDialog(BuildContext context, String message) {
    return showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Confirm'),
            content: Text(message),
            actions: <Widget>[
              TextButton(
                child: const Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
              ),
              TextButton(
                child: const Text('Confirm'),
                onPressed: () {
                  Navigator.of(context).pop(true); // Close the dialog
                },
              ),
            ],
          );
        });
  }
}
