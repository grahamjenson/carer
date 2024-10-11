import 'package:carer/services/updaters/ns_entries.dart';
import 'package:carer/services/updaters/ns_profile.dart';
import 'package:carer/services/updaters/ns_properties.dart';
import 'package:carer/services/updaters/ns_treatments.dart';
import 'package:carer/services/updaters/updater.dart';

class UpdateService {
  // is a singleton
  static final UpdateService _instance = UpdateService._();
  factory UpdateService() => _instance;

  late NSPropertiesUpdater nsSummaryUpdater;
  late NSEntriesUpdater nsEntriesUpdater;
  late NSTreatmentsUpdater nsTreatmentUpdater;
  late NSProfileUpdater nsProfileUpdater;

  List<Updater> get updaters => [
        nsSummaryUpdater,
        nsEntriesUpdater,
        nsTreatmentUpdater,
        nsProfileUpdater,
      ];

  UpdateService._() {
    nsSummaryUpdater = NSPropertiesUpdater();
    nsEntriesUpdater = NSEntriesUpdater();
    nsTreatmentUpdater = NSTreatmentsUpdater();
    nsProfileUpdater = NSProfileUpdater();
  }

  start() {
    for (var element in updaters) {
      element.start();
    }
  }

  bool forceUpdateAll() {
    for (var element in updaters) {
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
