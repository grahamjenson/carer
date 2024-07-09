import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:carer/sql/carer_db.dart';
import 'package:carer/sql/key_value_store.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/utils/logs.dart';
import 'package:carer/widgets/settings/debug_pages/log_error_page.dart';
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

Future<String> writeLog() async {
  final directory = await getTemporaryDirectory(); // Use getApplicationDocumentsDirectory() for persistent storage
  final logFile = File('${directory.path}/app_logs.txt');
  await logFile.writeAsString(ALogger().getPrettyLogs(), mode: FileMode.append);
  return logFile.path;
}

class DebugSettingsWidget extends AbstractSettingsSection {
  const DebugSettingsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return AWatch((context) {
      return SettingsSection(
        title: const Text('Debug'),
        tiles: [
          SettingsTile.navigation(
            title: const Text("Share DB"),
            descriptionInlineIos: true,
            leading: const Icon(UniconsLine.bug),
            onPressed: (context) async {
              var dbpath = await CarerDB.getPath();
              var kvpath = await KeyValueStore.getPath();
              var logPath = await writeLog();

              await zipAndShare([dbpath, kvpath, logPath], "carer_debug_${clock.now().millisecondsSinceEpoch}");
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
