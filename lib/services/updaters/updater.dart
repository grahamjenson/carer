// An Updater Manages the time that the data is updated
import 'dart:async';

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

  forceUpdate() {
    _forceUpdate = true;
  }

  void start() {
    Timer.periodic(intervalToCheck, (Timer t) async {
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
