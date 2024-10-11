import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:carer/services/background_service.dart';
import 'package:carer/services/update_service.dart';
import 'package:carer/sql/carer_db.dart';
import 'package:carer/sql/key_value_store.dart';
import 'package:carer/sql/log_db.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/utils/logs.dart';
import 'package:carer/widgets/settings/debug_pages/alarm_log_page.dart';
import 'package:carer/widgets/settings/debug_pages/log_error_page.dart';
import 'package:carer/widgets/settings/debug_pages/nightscout_debug.dart';
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_settings_ui/flutter_settings_ui.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:unicons/unicons.dart';

Future<void> zipAndShare(List<String> filePaths, String zipFileName) async {
  // Create a zip file from the list of files
  var encoder = ZipFileEncoder();
  String tempDir = (await getTemporaryDirectory()).path;
  String zipFilePath = '$tempDir/$zipFileName.zip';
  encoder.create(zipFilePath);
  for (String path in filePaths) {
    encoder.addFile(File(path));
  }
  encoder.close();

  alog("Zip File location $zipFilePath");

  // Share the zip file
  final result = await Share.shareXFiles([XFile(zipFilePath)], text: 'Here are the files');
  if (result.status == ShareResultStatus.success) {
    alog('Files shared successfully');
  }
}

Future<String> writeFile(String contents, String name) async {
  final directory = await getTemporaryDirectory(); // Use getApplicationDocumentsDirectory() for persistent storage
  final logFile = File('${directory.path}/$name');
  await logFile.writeAsString(contents, mode: FileMode.append);
  return logFile.path;
}

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
      getAlarms(),
      getShareLogs(),
      getServices(),
    ];

    if (Platform.isIOS || Platform.isAndroid) {
      sections.add(getBackgroundDo());
    }

    return sections;
  }

  SettingsSection getErrorLog() {
    return SettingsSection(
      title: const Text('Error Logs'),
      tiles: [
        SettingsTile.navigation(
          title: const Text("Error Log"),
          descriptionInlineIos: true,
          leading: const Icon(UniconsLine.bug),
          onPressed: (context) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const LogErrorPage()),
            );
          },
        )
      ],
    );
  }

  SettingsSection getAlarms() {
    return SettingsSection(
      title: const Text('Alarms'),
      tiles: [
        SettingsTile.navigation(
          title: const Text("Alarms"),
          descriptionInlineIos: true,
          leading: const Icon(UniconsLine.bug),
          onPressed: (context) async {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AlarmLogPage()),
            );
          },
        )
      ],
    );
  }

  SettingsSection getShareLogs() {
    return SettingsSection(
      title: const Text('Alarms'),
      tiles: [
        SettingsTile.navigation(
          title: const Text("Share Debug Files"),
          descriptionInlineIos: true,
          leading: const Icon(UniconsLine.bug),
          onPressed: (context) async {
            List<String> paths = [];

            // Add main DB and KV DB
            paths.add(await CarerDB.getPath());
            paths.add(await KeyValueStore.getPath());
            paths.add(await LogDB.getPath());

            // Add logs
            paths.add(await writeFile(ALogger().getPrettyLogs(), "app_logs.txt"));

            // Add the last raw value from all updaters
            for (var updater in UpdateService().updaters) {
              paths.add(await writeFile(updater.raw, "${updater.runtimeType.toString()}.json"));
            }

            zipAndShare(paths, "carer_debug_${clock.now().millisecondsSinceEpoch}");
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
          leading: const Icon(UniconsLine.bug),
          onPressed: (context) async {
            // manually schedule the background task to be run
            // print("Stargin Background Do");
            // await BackgroundService().run();
            // print("Done Background Do");
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
        SettingsTile(
          title: const Text("NightScout"),
          leading: const Icon(UniconsLine.bug),
          onPressed: (context) async {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const NightScoutServiceDebugPage()),
            );
          },
        )
      ],
    );
  }
}
