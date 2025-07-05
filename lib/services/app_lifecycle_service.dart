import 'dart:io';

import 'package:carer/main.dart';
import 'package:carer/models/sql/events/app_state_change_event.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/utils/logs.dart';
import 'package:clock/clock.dart';
import 'package:flutter/widgets.dart';

class AppLifecycleService extends State<MyApp> with WidgetsBindingObserver {
  ASignal<DateTime> lastResumed = ASignal(clock.ago(days: 1), debugLabel: "lastResumed");
  ASignal<DateTime> lastPaused = ASignal(clock.now(), debugLabel: "lastPaused");
  ASignal<AppLifecycleState> lastState = ASignal(AppLifecycleState.resumed, debugLabel: "lastState");
  ASignal<DateTime> lastChangeScreen = ASignal(clock.ago(days: 1), debugLabel: "lastChangeScreen");
  ASignal<DateTime> lastInteraction = ASignal(clock.now(), debugLabel: "lastInteraction");

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

  bool get wasScreenChanged5SecondsAgo => clock.now().difference(lastChangeScreen.value).inSeconds < 5;

  bool get stateResumed => lastState.value == AppLifecycleState.resumed;
  bool get stateChanged10SecondsAgo => clock.now().difference(lastState.lastSet).inSeconds.abs() < 10;
  bool get stateChanged2SecondsAgo => clock.now().difference(lastState.lastSet).inMilliseconds.abs() < 2000;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Put into a microtask to avoid any issues with the lifecycle state
    Future.microtask(() {
      // WARNING: this works differently on all platforms, so anything complicated should be platform specific
      lastState.value = state;
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
    });
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    throw UnimplementedError();
  }
}

void updateOnRouteChange() {
  AppLifecycleService().lastChangeScreen.value = clock.now();
}

class NavigationChangeObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    // This may happen during a build of a widget, since signals are syncrhonous with drawing can cause errors.
    // To stop that we are putting in an aynshconous call and not waiting
    Future.microtask(updateOnRouteChange);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    Future.microtask(updateOnRouteChange);
  }
}
