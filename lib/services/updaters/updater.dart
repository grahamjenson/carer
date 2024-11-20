// An Updater Manages the time that the data is updated
import 'dart:async';

import 'package:carer/services/app_lifecycle_service.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/utils/logs.dart';
import 'package:clock/clock.dart';

abstract class Updater {
  Duration intervalToCheck;
  Duration maxAgeBeforeChecking;
  DateTime lastUpdated = clock.daysAgo(3);
  DateTime lastSuccessfulUpdate = clock.daysAgo(3);
  bool _forceUpdate = false;
  Updater({required this.intervalToCheck, required this.maxAgeBeforeChecking});

  Future<bool> update();
  String raw = "";

  Duration get updatedAge => clock.now().difference(lastUpdated);
  Duration get successfulAge => clock.now().difference(lastSuccessfulUpdate);

  forceUpdate() {
    _forceUpdate = true;
  }

  void start() {
    aeffect(() {
      // If the app has been closed for 5 seconds force an update so that we get new information
      DateTime paused = AppLifecycleService().lastPaused.peek();
      DateTime reload = AppLifecycleService().lastResumed.value;
      var diff = reload.difference(paused);

      if (diff.inSeconds > 5) {
        // If the app has been closed a while force an update;

        _forceUpdate = true;
      }
    }, debugLabel: "${runtimeType}LastResumedUpdaterEffect");

    Timer.periodic(intervalToCheck, (Timer t) async {
      // If this tries to update too quickly after reopening it will cause an OS error
      if (AppLifecycleService().wasResumed2SecondsAgo) {
        return;
      }

      var reasons = shouldUpdate();

      if (reasons.isNotEmpty) {
        alog("Updating $runtimeType because ${reasons.join(", ")}");

        // We always update
        lastUpdated = DateTime.now();
        var (ret, err) = await go(update());

        if (err != null || ret == null) {
          alog("Error updating $runtimeType: $err\n last update: $lastSuccessfulUpdate");
        } else {
          lastSuccessfulUpdate = DateTime.now();
        }
      }
    });
  }

  Duration timeSinceLastSuccessfulUpdate() {
    return DateTime.now().difference(lastSuccessfulUpdate);
  }

  final List<String> _externalReasons = [];
  addExternalReason(String reason) => _externalReasons.add(reason);

  List<String> shouldUpdate() {
    List<String> reasons = [];

    if (_forceUpdate) {
      reasons.add("Forced update");
      _forceUpdate = false;
    }

    reasons.addAll(_externalReasons);
    _externalReasons.clear();

    var now = DateTime.now();
    var lastUpdated = this.lastUpdated;
    var age = now.difference(lastUpdated);
    if (age > maxAgeBeforeChecking) {
      reasons.add("Age older than ${maxAgeBeforeChecking.inSeconds} seconds");
    }

    return reasons;
  }
}
