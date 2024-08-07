import 'package:carer/main.dart';
import 'package:carer/utils/logs.dart';
import 'package:clock/clock.dart';
import 'package:flutter/widgets.dart';
import 'package:signals/signals_flutter.dart';

class AppLifecycleService extends State<MyApp> with WidgetsBindingObserver {
  Signal<DateTime> lastResumed = Signal(clock.now());

  //singleton
  static final AppLifecycleService _instance = AppLifecycleService._();
  factory AppLifecycleService() => _instance;
  AppLifecycleService._() {
    WidgetsBinding.instance.addObserver(this);
  }

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
