import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:carer/services/update_service.dart';
import 'package:carer/sql/carer_db.dart';
import 'package:carer/sql/key_value_store.dart';
import 'package:carer/sql/log_db.dart';
import 'package:carer/utils/logs.dart';
import 'package:clock/clock.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ShareFileService {
  static final ShareFileService _singleton = ShareFileService._();

  factory ShareFileService() => _singleton;

  ShareFileService._();

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
    final result = await Share.shareXFiles([XFile(zipFilePath)]);
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

  void shareFiles() async {
    List<String> paths = [];

    // Add main DB and KV DB
    paths.add(await CarerDB.getPath());
    paths.add(await KeyValueStore.getPath());
    paths.add(await LogDB.getPath());

    // Add the last raw value from all updaters
    for (var updater in UpdateService().updaters) {
      paths.add(await writeFile(updater.raw, "${updater.runtimeType.toString()}.json"));
    }

    zipAndShare(paths, "carer_debug_${clock.now().millisecondsSinceEpoch}");
  }
}
