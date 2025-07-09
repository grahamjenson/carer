import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  // Singleton
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  NotificationService._() {
    _init();
  }

  Future<void> _init() async {
    // Initialization settings for Android
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    // Initialization settings for iOS
    const DarwinInitializationSettings initializationSettingsDarwin = DarwinInitializationSettings(
      requestSoundPermission: false,
      requestBadgePermission: false,
      requestAlertPermission: false,
    );

    // Initialization settings for Linux
    const LinuxInitializationSettings initializationSettingsLinux = LinuxInitializationSettings(
      defaultActionName: 'Open',
    );

    // Choose the right initialization settings based on the platform
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
      macOS: initializationSettingsDarwin,
      linux: initializationSettingsLinux,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<bool> showNotification(String title, String subtitle, String? body) async {
    var allowed = await requestPermissions();
    if (allowed == null || allowed == false) {
      print("Notification permission not granted $allowed");
      return false;
    }

    print("Showing notification: $title, $subtitle, $body");

    // TODO: Android Fix this
    const androidSpecifics = AndroidNotificationDetails(
      'nz.t1d.carer',
      'Carer Notification',
      channelDescription: 'Carer Alarm Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );

    var iosSpecifics = DarwinNotificationDetails(
      sound: 'notif.aiff',
      presentSound: true,
      presentAlert: true,
      presentBadge: true,
      presentBanner: true,
      subtitle: subtitle,
      interruptionLevel: InterruptionLevel.critical,
    );

    var macosSpecifics = DarwinNotificationDetails(
      sound: 'notif.aiff',
      presentSound: true,
      presentAlert: true,
      presentBadge: true,
      presentBanner: true,
      subtitle: subtitle,
      interruptionLevel: InterruptionLevel.critical,
    );

    NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidSpecifics,
      iOS: iosSpecifics,
      macOS: macosSpecifics,
      linux: const LinuxNotificationDetails(),
    );
    await flutterLocalNotificationsPlugin.show(
      0, // Notification ID
      title,
      body,
      platformChannelSpecifics,
    );
    return true;
  }

  Future<bool?>? requestPermissions() {
    if (Platform.isIOS) {
      return flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    } else if (Platform.isMacOS) {
      return flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<MacOSFlutterLocalNotificationsPlugin>()?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    }
    return Future.value(true);
  }
}
