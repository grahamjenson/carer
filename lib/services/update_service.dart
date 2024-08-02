import 'package:carer/services/updaters/ns_entries.dart';
import 'package:carer/services/updaters/ns_profile.dart';
import 'package:carer/services/updaters/ns_properties.dart';
import 'package:carer/services/updaters/ns_treatments.dart';
import 'package:carer/services/updaters/updater.dart';

class UpdateService {
  // is a singleton
  static final UpdateService _instance = UpdateService._();
  factory UpdateService() => _instance;

  List<Updater> updaters = [];
  UpdateService._() {
    var nsSummaryUpdater = NSPropertiesUpdater();
    var nsEntriesUpdater = NSEntriesUpdater();
    var nsTreatmentUpdater = NSTreatmentsUpdater();
    var nsProfileUpdater = NSProfileUpdater();

    updaters.addAll([nsSummaryUpdater, nsEntriesUpdater, nsTreatmentUpdater, nsProfileUpdater]);
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
