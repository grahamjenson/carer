import 'package:carer/services/settings/device_settings.dart';
import 'package:carer/utils/futures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_settings_ui/flutter_settings_ui.dart';
import 'package:unicons/unicons.dart';

class DeviceSettingsWidget extends AbstractSettingsSection {
  const DeviceSettingsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return AWatch((context) {
      var tiles = [
        cannulaAge(context),
        sensorAge(context),
      ];

      return SettingsSection(
        title: const Text('Device Settings'),
        tiles: tiles,
      );
    });
  }

  SettingsTile cannulaAge(BuildContext context) {
    return intSelector(
      "Cannula Max Age (Days)",
      () => DeviceSettings().cannulaDays,
      () => DeviceSettings().cannulaDays++,
      () => DeviceSettings().cannulaDays--,
    );
  }

  SettingsTile sensorAge(BuildContext context) {
    return intSelector(
      "Sensor Max Age (Days)",
      () => DeviceSettings().sensorDays,
      () => DeviceSettings().sensorDays++,
      () => DeviceSettings().sensorDays--,
    );
  }
}

SettingsTile intSelector(String title, Function getInt, GestureTapCallback inc, GestureTapCallback dec) {
  return SettingsTile(
    title: Text(title),
    trailing: Row(children: [
      InkWell(
          onTap: dec,
          child: const Icon(
            UniconsLine.minus,
          )),
      SizedBox(
          width: 50,
          child: InkWell(
            borderRadius: BorderRadius.circular(8), // Match the border radius
            splashColor: Colors.blueAccent.withOpacity(0.3), // Splash color
            highlightColor: Colors.blueAccent.withOpacity(0.1), // Highlight color

            child: Text(
              getInt().toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ), // Add padding inside the border
          )),
      InkWell(onTap: inc, child: const Icon(UniconsLine.plus)),
    ]),
  );
}
