import 'dart:io';

import 'package:carer/main.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/utils/logs.dart';
import 'package:clock/clock.dart';
import 'package:flutter/widgets.dart';

class AppLifecycleService extends State<MyApp> with WidgetsBindingObserver {
  ASignal<DateTime> lastResumed = ASignal(clock.now(), debugLabel: "LastResumed");
  ASignal<DateTime> lastChangeScreen = ASignal(clock.now(), debugLabel: "changeScreen");

  //singleton
  static final AppLifecycleService _instance = AppLifecycleService._();
  factory AppLifecycleService() => _instance;
  AppLifecycleService._() {
    if (Platform.isAndroid || Platform.isIOS) {
      // Resuming an app on desktop also means when selected the window, which is a bit different
      WidgetsBinding.instance.addObserver(this);
    }
  }

  bool get wasRecentlyResumed => clock.now().difference(lastResumed.value).inSeconds < 9;

  bool get wasRecentlyScreenChanged => clock.now().difference(lastChangeScreen.value).inSeconds < 9;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // WARNING: this works differently on all platforms, so anything complicated should be platform specific
    switch (state) {
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.paused:
        break;
      case AppLifecycleState.resumed:
        alog("AppLifecycleService: Resumed");
        lastResumed.value = clock.now();
        break;
      case AppLifecycleState.hidden:
        break;
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    throw UnimplementedError();
  }
}

class NavigationChangeObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    AppLifecycleService().lastChangeScreen.value = clock.now();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    // If poping to the inital route, then remove the lastScreenChange
    if (previousRoute?.settings.name == "/") {
      // TODO: a bit hacky, needs a rename like LastNotOnMainScreen
      AppLifecycleService().lastChangeScreen.value = clock.now().subtract(const Duration(minutes: 1));
    } else {
      AppLifecycleService().lastChangeScreen.value = clock.now();
    }
  }
}
