// An Updater Manages the time that the data is updated
import 'dart:async';

import 'package:carer/utils/futures.dart';
import 'package:carer/utils/logs.dart';

abstract class Updater {
  Future<bool> update();

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

  final List<String> _externalReasons = [];
  addExternalReason(String reason) => _externalReasons.add(reason);

  List<String> shouldUpdate() {
    List<String> reasons = [];
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

  Duration intervalToCheck;
  Duration maxAgeBeforeChecking;

  Updater({required this.intervalToCheck, required this.maxAgeBeforeChecking});

  DateTime lastUpdated = DateTime(1970);
  DateTime lastSuccessfulUpdate = DateTime(1970);
}
