import 'package:carer/nsclient/nsclient.dart';
import 'package:carer/services/settings/secure_settings.dart';
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
                SettingsTile.navigation(
                  title: const Text('Add 1 Carb'),
                  onPressed: (context) {
                    var (nsURL, nsToken) = SecureSettings().nightscoutURLAndToken;
                    NSClient().addCarbs(nsURL, nsToken, 1);
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
            SettingsSection(
              title: const Text('Temp Target'),
              tiles: [
                SettingsTile.switchTile(
                  initialValue: false,
                  onToggle: (aha) => null,
                  title: const Text('Temp Target'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
