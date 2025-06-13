import 'dart:io';

import 'package:carer/models/flow_data.dart';
import 'package:carer/services/background_service.dart';
import 'package:carer/services/notification_service.dart';
import 'package:carer/services/settings/secure_settings.dart';
import 'package:carer/services/share_file_service.dart';
import 'package:carer/services/toast_service.dart';
import 'package:carer/services/ui/icons.dart';
import 'package:carer/sql/carer_db.dart';
import 'package:carer/utils/futures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_settings_ui/flutter_settings_ui.dart';
import 'package:go_router/go_router.dart';

class DebugSettingsPage extends StatelessWidget {
  const DebugSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug'),
      ),
      body: AWatch(
        (context) {
          return SettingsList(
            sections: getSections(),
          );
        },
        debugLabel: "DebugSettingsPage",
      ),
    );
  }

  List<SettingsSection> getSections() {
    List<SettingsSection> sections = [
      getErrorLog(),
      getShareLogs(),
      getServices(),
      getTestButtons(),
      getResetButtons(),
    ];

    if (Platform.isIOS || Platform.isAndroid) {
      sections.add(getBackgroundDo());
    }

    return sections;
  }

  SettingsSection getResetButtons() {
    return SettingsSection(
      title: const Text('Reset Buttons'),
      tiles: [
        SettingsTile(
          title: const Text("Reset Onboarding Data"),
          leading: const Icon(CarerIcons.SETTINGS_DEBUG),
          onPressed: (context) async {
            FlowData().agreedTermsOfServicePrivacy = null;

            GoRouter.of(context).refresh();
          },
        ),
        SettingsTile(
          title: const Text("Reset NightScout URL"),
          leading: const Icon(CarerIcons.SETTINGS_DEBUG),
          onPressed: (context) async {
            SecureSettings().debugDeleteNSValues();
            GoRouter.of(context).refresh();
          },
        ),
        SettingsTile(
          title: const Text("Reset and Delete Database Data"),
          description: const Text("This deletes all NS Data but leaves settings like alarms and Nightscout URL"),
          descriptionInlineIos: true,
          leading: const Icon(CarerIcons.SETTINGS_DEBUG),
          onPressed: (context) async {
            var db = await CarerDB.instance;
            await CarerDB.dropAll(db.db);
            await CarerDB.createAll(db.db);
            ToastService().showSuccess("Reset All Data");
          },
        ),
      ],
    );
  }

  SettingsSection getTestButtons() {
    return SettingsSection(
      title: const Text('Test Buttons'),
      tiles: [
        SettingsTile(
          title: const Text("Test Error Toast"),
          leading: const Icon(CarerIcons.SETTINGS_DEBUG),
          onPressed: (context) async {
            ToastService().showError("Test Error", description: "this is a test error");
          },
        ),
        SettingsTile(
          title: const Text("Test Success Toast"),
          leading: const Icon(CarerIcons.SETTINGS_DEBUG),
          onPressed: (context) async {
            ToastService().showSuccess("Test Success", description: "this is a test success");
          },
        ),
        SettingsTile(
          title: const Text("Test Notification"),
          leading: const Icon(CarerIcons.SETTINGS_DEBUG),
          onPressed: (context) async {
            NotificationService().showNotification("Alarm", "Text on the Notification");
          },
        ),
      ],
    );
  }

  SettingsSection getErrorLog() {
    return SettingsSection(
      title: const Text('Error Logs'),
      tiles: [
        SettingsTile.navigation(
          title: const Text("Error Log"),
          descriptionInlineIos: true,
          leading: const Icon(CarerIcons.SETTINGS_DEBUG),
          onPressed: (context) {
            GoRouter.of(context).go("/settings/debug/log_errors");
          },
        )
      ],
    );
  }

  SettingsSection getShareLogs() {
    return SettingsSection(
      title: const Text('Share'),
      tiles: [
        SettingsTile.navigation(
          title: const Text("Share Debug Files"),
          descriptionInlineIos: true,
          leading: const Icon(CarerIcons.SETTINGS_DEBUG),
          onPressed: (BuildContext context) async {
            ShareFileService().shareFiles();
          },
        ),
      ],
    );
  }

  SettingsSection getBackgroundDo() {
    return SettingsSection(
      title: const Text('Background Do'),
      tiles: [
        SettingsTile.navigation(
          title: const Text("Background Do"),
          descriptionInlineIos: true,
          leading: const Icon(CarerIcons.SETTINGS_DEBUG),
          onPressed: (context) async {
            BackgroundService().onFetch("com.transistorsoft.fetch");
          },
        )
      ],
    );
  }

  SettingsSection getServices() {
    return SettingsSection(
      title: const Text('Services'),
      tiles: [
        SettingsTile.navigation(
          title: const Text("NightScout"),
          leading: const Icon(CarerIcons.SETTINGS_DEBUG),
          onPressed: (context) async {
            GoRouter.of(context).go("/settings/debug/nightscout_debug");
          },
        )
      ],
    );
  }
}
