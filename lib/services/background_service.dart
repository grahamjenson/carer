import 'package:background_fetch/background_fetch.dart';
import 'package:carer/models/clean_sgv.dart';
import 'package:carer/services/alarms_service.dart';
import 'package:carer/services/notification_service.dart';
import 'package:carer/services/settings/alarm_alert_settings.dart';
import 'package:carer/services/update_service.dart';
import 'package:carer/utils/logs.dart';

import 'settings/alarm_settings.dart';

class BackgroundService {
  static final BackgroundService _singleton = BackgroundService._();
  factory BackgroundService() => _singleton;

  BackgroundService._();

  BackgroundFetchConfig config = BackgroundFetchConfig(
    minimumFetchInterval: 15,
    stopOnTerminate: false,
    startOnBoot: true,
    enableHeadless: true,
    requiresBatteryNotLow: false,
    requiresCharging: false,
    requiresStorageNotLow: false,
    requiresDeviceIdle: false,
    requiredNetworkType: NetworkType.ANY,
  );

  Future<void> configure() async {
    int status = await BackgroundFetch.configure(config, onFetch, onTimeout);
    doublelog('BackgroundFetch: configure success: $status');
  }

  Future<void> start() async {
    int status = await BackgroundFetch.start();
    doublelog('BackgroundFetch: start success: $status');
  }

  Future<bool> registerHeadlessTask() async {
    // Andoird only
    doublelog('BackgroundFetch: registerHeadlessTask');
    return BackgroundFetch.registerHeadlessTask(backgroundFetchHeadlessTask);
  }

  void onFetch(String taskId) async {
    try {
      doublelog("BackgroundFetch: Event received $taskId ${CleanSGV.lastSGV.value}");
      var x = await UpdateService().updateAll();
      doublelog("BackgroundFetch: updateALL $x ${CleanSGV.lastSGV.value}");
      // Because their are asynchronous signals we need to wait a little bit for all values to propagate
      await Future.delayed(const Duration(milliseconds: 500));
      doublelog("BackgroundFetch: updateALL After sleep $x ${CleanSGV.lastSGV.value}");

      var (newTriggeredAlarms, _) = AlarmsService().calculateAlarms();
      doublelog("BackgroundFetch: calculateAlarms: $newTriggeredAlarms");
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
        if (AlarmSettings().disableAlarms) {
          doublelog("BackgroundFetch: Disabled Alarms $svgstr $alarms");
        } else if (!AlarmAlertSettings().enableNotifications) {
          doublelog("BackgroundFetch: Disabled Notifications $svgstr $alarms");
        } else {
          doublelog("BackgroundFetch: Notification $svgstr $alarms");
          NotificationService().showNotification("Alarm", "$svgstr $alarms");
        }
      }
      doublelog("BackgroundFetch: FINISHED ");
    } catch (err, st) {
      doublelog("BackgroundFetch: onFetch error: $err, $st");
    } finally {
      BackgroundFetch.finish(taskId);
      doublelog("BackgroundFetch: EXITING");
    }
  }

  void onTimeout(String taskId) async {
    doublelog("BackgroundFetch: onTimeout");
    // just log the timeout
    BackgroundFetch.finish(taskId);
  }

  void scheduleTask() {
    doublelog("BackgroundFetch: Scheduling task");
    BackgroundFetch.scheduleTask(TaskConfig(
      taskId: "com.transistorsoft.fetch",
      delay: 5000, // <-- milliseconds
    ));
  }
}

// ANDROID ONLY RUN WHEN PROGRAM EXITED
@pragma('vm:entry-point')
void backgroundFetchHeadlessTask(HeadlessTask task) async {
  doublelog("BackgroundFetch: backgroundFetchHeadlessTask");
  String taskId = task.taskId;
  bool isTimeout = task.timeout;
  // This task has exceeded its allowed running-time.
  // You must stop what you're doing and immediately .finish(taskId)
  doublelog("BackgroundFetch: Headless task timed-out: $taskId $isTimeout");
  BackgroundFetch.finish(taskId);
}

void doublelog(String message) {
  print(message);
  alog(message);
}
