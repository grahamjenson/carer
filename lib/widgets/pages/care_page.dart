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
                SettingsTile.switchTile(
                  initialValue: false,
                  onToggle: (aha) => null,
                  title: const Text('Carbs'),
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
