import 'dart:isolate';

import 'package:background_fetch/background_fetch.dart';
import 'package:carer/services/update_service.dart';
import 'package:carer/utils/logs.dart';

void setupBackgroundFetch() async {
  var config = BackgroundFetchConfig(
      minimumFetchInterval: 15,
      stopOnTerminate: false,
      enableHeadless: true,
      requiresBatteryNotLow: false,
      requiresCharging: false,
      requiresStorageNotLow: false,
      requiresDeviceIdle: false,
      requiredNetworkType: NetworkType.ANY);

  int status = await BackgroundFetch.configure(config, onFetch, onTimeout);
  alog('BackgroundFetch: configure success: $status');
  // Andoird only
  BackgroundFetch.registerHeadlessTask(backgroundFetchHeadlessTask);
}

void onFetch(String taskId) async {
  try {
    debugPrint = true;
    print("BBB ${Isolate.current.debugName}");
    alog("BackgroundFetch(${Isolate.current.debugName}): Event received $taskId");

    var x = await UpdateService().updateAll();
    alog("BackgroundFetch: updateALL $x");
  } catch (err, st) {
    alog("BackgroundFetch: onFetch error: $err, $st");
  } finally {
    debugPrint = false;
    BackgroundFetch.finish(taskId);
  }
}

void onTimeout(String taskId) async {
  // just log the timeout
  BackgroundFetch.finish(taskId);
}

// ANDROID ONLY RUN WHEN PROGRAM EXITED
@pragma('vm:entry-point')
void backgroundFetchHeadlessTask(HeadlessTask task) async {
  alog("BackgroundFetch] backgroundFetchHeadlessTask");
  String taskId = task.taskId;
  bool isTimeout = task.timeout;
  // This task has exceeded its allowed running-time.
  // You must stop what you're doing and immediately .finish(taskId)
  alog("BackgroundFetch: Headless task timed-out: $taskId $isTimeout");
  BackgroundFetch.finish(taskId);
}
