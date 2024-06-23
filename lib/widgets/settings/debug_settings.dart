import 'package:carer/sql/carer_db.dart';
import 'package:carer/widgets/settings/debug_pages/log_error_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_settings_ui/flutter_settings_ui.dart';
import 'package:share_plus/share_plus.dart';
import 'package:signals/signals_flutter.dart';
import 'package:unicons/unicons.dart';

class DebugSettingsWidget extends AbstractSettingsSection {
  const DebugSettingsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      return SettingsSection(
        title: const Text('Debug'),
        tiles: [
          SettingsTile.navigation(
            title: const Text("Share DB"),
            descriptionInlineIos: true,
            leading: const Icon(UniconsLine.bug),
            onPressed: (context) async {
              var path = await CarerDB.getPath();
              print("Sharing DB at $path");
              final result = await Share.shareXFiles([XFile(path)], text: 'DB');

              if (result.status == ShareResultStatus.success) {
                print('Thank you for sharing the DB');
              }
            },
          ),
          SettingsTile.navigation(
            title: const Text("Error Log"),
            descriptionInlineIos: true,
            leading: const Icon(UniconsLine.bug),
            onPressed: (context) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LogErrorPage()),
              );
            },
          ),
        ],
      );
    });
  }
}
