import 'dart:io';

import 'package:carer/main.dart';
import 'package:carer/models/sql/events/app_state_change_event.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/utils/logs.dart';
import 'package:clock/clock.dart';
import 'package:flutter/widgets.dart';

class AppLifecycleService extends State<MyApp> with WidgetsBindingObserver {
  ASignal<DateTime> lastResumed = ASignal(clock.ago(days: 1), debugLabel: "LastResumed");
  ASignal<DateTime> lastPaused = ASignal(clock.now(), debugLabel: "LastPaused");
  ASignal<AppLifecycleState> lastState = ASignal(AppLifecycleState.resumed, debugLabel: "LastState");
  ASignal<DateTime> lastChangeScreen = ASignal(clock.ago(days: 1), debugLabel: "changeScreen");

  //singleton
  static final AppLifecycleService _instance = AppLifecycleService._();
  factory AppLifecycleService() => _instance;
  AppLifecycleService._() {
    if (Platform.isAndroid || Platform.isIOS) {
      // Resuming an app on desktop also means when selected the window, which is a bit different
      WidgetsBinding.instance.addObserver(this);
    }
  }

  bool get wasResumed1SecondsAgo => clock.now().difference(lastResumed.value).inMilliseconds < 1000;
  bool get wasResumed2SecondsAgo => clock.now().difference(lastResumed.value).inMilliseconds < 2000;

  bool get wasResumed10SecondsAgo => clock.now().difference(lastResumed.value).inSeconds < 9;

  bool get wasRecentlyScreenChanged => clock.now().difference(lastChangeScreen.value).inSeconds < 9;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // WARNING: this works differently on all platforms, so anything complicated should be platform specific
    switch (state) {
      case AppLifecycleState.inactive:
        alog("AppLifecycleService: Inactive");
        break;
      case AppLifecycleState.paused:
        alog("AppLifecycleService: paused");
        AppStateEvent.appStateChange(AppStateEventType.paused);
        lastPaused.value = clock.now();
        break;
      case AppLifecycleState.resumed:
        alog("AppLifecycleService: Resumed");
        AppStateEvent.appStateChange(AppStateEventType.resumed);
        lastResumed.value = clock.now();
        break;
      case AppLifecycleState.hidden:
        alog("AppLifecycleService: hidden");

        break;
      case AppLifecycleState.detached:
        alog("AppLifecycleService: detached");
        break;
    }
    lastState.value = state;
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
