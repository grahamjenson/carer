import 'package:background_fetch/background_fetch.dart';
import 'package:carer/models/clean_sgv.dart';
import 'package:carer/services/alarms_service.dart';
import 'package:carer/services/notification_service.dart';
import 'package:carer/services/update_service.dart';
import 'package:carer/utils/logs.dart';

class BackgroundService {
  static final BackgroundService _singleton = BackgroundService._();
  factory BackgroundService() => _singleton;

  BackgroundService._() {
    setupBackgroundFetch();
  }

  BackgroundFetchConfig config = BackgroundFetchConfig(
      minimumFetchInterval: 15,
      stopOnTerminate: false,
      enableHeadless: true,
      requiresBatteryNotLow: false,
      requiresCharging: false,
      requiresStorageNotLow: false,
      requiresDeviceIdle: false,
      requiredNetworkType: NetworkType.ANY);

  Future<bool> run() async {
    print("Scheduling task");
    return await BackgroundFetch.scheduleTask(TaskConfig(
      taskId: "com.transistorsoft.fetch",
      delay: 5000,
    ));
  }

  void setupBackgroundFetch() async {
    int status = await BackgroundFetch.configure(config, onFetch, onTimeout);
    alog('BackgroundFetch: configure success: $status');
    // Andoird only
    BackgroundFetch.registerHeadlessTask(backgroundFetchHeadlessTask);
  }

  void onFetch(String taskId) async {
    try {
      print("Running Background Fetch");
      alog("BackgroundFetch: Event received $taskId");
      var x = await UpdateService().updateAll();
      alog("BackgroundFetch: updateALL $x");

      var (newTriggeredAlarms, _) = AlarmsService().calculateAlarms();
      if (newTriggeredAlarms.isNotEmpty) {
        CleanSGV? sgv = CleanSGV.lastSGV.value;

        var svgstr = "unknwon sgv";
        if (sgv != null) {
          svgstr = "${sgv.sgvStr()}${sgv.rate5mWithSign()}, ${sgv.age.inMinutes}m ago";
        }

        String alarms = "";
        for (var alarm in newTriggeredAlarms) {
          alarms += alarm.toString();
        }

        NotificationService().showNotification("Alarm", "$svgstr $alarms");
      }
    } catch (err, st) {
      alog("BackgroundFetch: onFetch error: $err, $st");
    } finally {
      BackgroundFetch.finish(taskId);
    }
  }

  void onTimeout(String taskId) async {
    // just log the timeout
    BackgroundFetch.finish(taskId);
  }
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
