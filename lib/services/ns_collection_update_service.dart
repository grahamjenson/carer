import 'dart:async';

import 'package:carer/nsclient/nsclient.dart';
import 'package:carer/services/app_lifecycle_service.dart';
import 'package:carer/services/collection_updaters/collection.dart';
import 'package:carer/services/collection_updaters/device_status.dart';
import 'package:carer/services/collection_updaters/entries.dart';
import 'package:carer/services/collection_updaters/profile.dart';
import 'package:carer/services/collection_updaters/treatments.dart';
import 'package:carer/services/settings/secure_settings.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/utils/logs.dart';

class NSCollectionUpdateService {
  // is a singleton
  static final NSCollectionUpdateService _instance = NSCollectionUpdateService._();
  factory NSCollectionUpdateService() => _instance;

  Duration intervalToCheck = const Duration(seconds: 5); // Check the last modified every 5 seconds

  NSEntriesUpdater nsEntries = NSEntriesUpdater();
  NSTreatmentsUpdater nsTreatments = NSTreatmentsUpdater();
  NSProfileUpdater nsProfile = NSProfileUpdater();
  NSDeviceStatusUpdater nsDeviceStatus = NSDeviceStatusUpdater();
  CollectionCollection fakeCollectionCollection = CollectionCollection();

  List<NSCollection> get collections => [
        nsEntries,
        nsTreatments,
        nsProfile,
        nsDeviceStatus,
        fakeCollectionCollection,
      ];

  NSCollectionUpdateService._();

  Timer? _timer;

  // stop stops the updates start started
  void stop() => _timer?.cancel();

  start() {
    for (var element in collections) {
      element.bootstrap(); // Download and do initial setting (usually of things far in the past like profile switchs or Sensor Change)
    }

    // Need to see if this is still needed, give we are now checking every 5 seconds
    // aeffect(() {
    //   // If the app has been closed for 5 seconds force an update so that we get new information
    //   DateTime paused = AppLifecycleService().lastPaused.peek();
    //   DateTime reload = AppLifecycleService().lastResumed.value;
    //   var diff = reload.difference(paused);

    //   if (diff.inSeconds > 5) {
    //     // If the app has been closed a while force an update;

    //     _forceUpdate = true;
    //   }
    // }, debugLabel: "${runtimeType}LastResumedUpdaterEffect");

    bool running = false;
    _timer?.cancel();
    _timer = Timer.periodic(intervalToCheck, (Timer t) async {
      if (running) {
        alog("Update already running, skipping this interval");
        return;
      }
      running = true;

      try {
        // When reopening the app immedialty this will immedialty update
        // before the LifeCycle observer has a change to update the state!
        await Future.delayed(const Duration(milliseconds: 100));
        // If this tries to update too quickly after reopening it will cause an OS error
        if (AppLifecycleService().wasResumed2SecondsAgo) {
          running = false;
          return;
        }

        var (nsURL, nsToken) = SecureSettings().nightscoutURLAndToken;
        var (lastModified, err) = await go(NSClient().getLastModified(nsURL, nsToken));
        if (err != null || lastModified == null) {
          alog("Error getting last modified: $err");
          running = false;
          return;
        }
        fakeCollectionCollection.lastSuccessfulUpdate = DateTime.now();
        fakeCollectionCollection.raw = [lastModified.raw];
        for (var collection in collections) {
          var newLastModified = lastModified.lastModifiedMap[collection.getCollectionName()];
          if (newLastModified == null) {
            continue;
          }

          var rawreset = false;
          if (collection.updateForce) {
            alog("Collection ${collection.getCollectionName()} force update");
            collection.raw = [];
            rawreset = true;
            collection.updateForce = false;
            await collection.bootstrap();
          }

          if (collection.lastModifiedMilliSeconds != newLastModified) {
            alog("Collection ${collection.getCollectionName()} last modified (old/new) ${collection.lastModifiedMilliSeconds} / $newLastModified");
            if (!rawreset) {
              // Append to the exsiting bootstrap
              collection.raw = [];
            }
            const wiggle = 10 * 60 * 1000; // 10 minutes in milliseconds
            var ret = await collection.update(newLastModified - wiggle);
            if (ret == true) {
              alog("Updated collection: ${collection.runtimeType}");
              collection.lastModifiedMilliSeconds = newLastModified;
              collection.lastSuccessfulUpdate = DateTime.now();
            }
          }
        }
      } finally {
        running = false;
      }
    });
  }

  bool forceUpdateAll() {
    for (var element in collections) {
      // Force pulling in more info
      element.forceUpdate();
    }
    return true;
  }

  Future<bool> forceUpdateAllWithUpdate() async {
    var all = true;
    for (var element in collections) {
      element.forceUpdate();
      all = all && await element.bootstrap();
    }
    return all;
  }
}

class CollectionCollection extends NSCollection {
  CollectionCollection() : super();

  @override
  String getCollectionName() {
    return "collections";
  }

  @override
  Future<bool> update(int lastModified) async {
    // Implement the update logic for the collections here
    return true;
  }

  @override
  Future<bool> bootstrap() async {
    return true;
  }
}
