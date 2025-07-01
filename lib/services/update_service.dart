import 'package:carer/services/updaters/ns_bootstrap.dart';
import 'package:carer/services/updaters/ns_device_status.dart';
import 'package:carer/services/updaters/ns_entries.dart';
import 'package:carer/services/updaters/ns_profile.dart';
import 'package:carer/services/updaters/ns_properties.dart';
import 'package:carer/services/updaters/ns_treatments.dart';
import 'package:carer/services/updaters/updater.dart';
import 'package:clock/clock.dart';

class UpdateService {
  // is a singleton
  static final UpdateService _instance = UpdateService._();
  factory UpdateService() => _instance;

  late NsBootstrap nsBootstrap;
  late NSPropertiesUpdater nsPropertiesUpdater;
  late NSEntriesUpdater nsEntriesUpdater;
  late NSTreatmentsUpdater nsTreatmentUpdater;
  late NSProfileUpdater nsProfileUpdater;
  late NSDeviceStatusUpdater nsDeviceStatusUpdater;

  List<Updater> get updaters => [
        nsPropertiesUpdater,
        nsEntriesUpdater,
        nsTreatmentUpdater,
        nsProfileUpdater,
        nsDeviceStatusUpdater,
      ];

  UpdateService._() {
    nsPropertiesUpdater = NSPropertiesUpdater();
    nsEntriesUpdater = NSEntriesUpdater();
    nsTreatmentUpdater = NSTreatmentsUpdater();
    nsProfileUpdater = NSProfileUpdater();
    nsDeviceStatusUpdater = NSDeviceStatusUpdater();
    nsBootstrap = NsBootstrap();
  }

  start() {
    for (var element in updaters) {
      element.start();
    }
    nsBootstrap.bootstrap();
  }

  bool forceUpdateAll() {
    for (var element in updaters) {
      // Force pulling in more info
      element.lastSuccessfulUpdate = clock.daysAgo(1);
      element.forceUpdate();
    }
    return true;
  }

  Future<bool> updateAll() async {
    var all = true;
    for (var element in updaters) {
      all = all && await element.update();
    }
    return all;
  }
}
