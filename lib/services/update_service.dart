import 'package:carer/services/updaters/ns_entries.dart';
import 'package:carer/services/updaters/ns_profile.dart';
import 'package:carer/services/updaters/ns_summary.dart';
import 'package:carer/services/updaters/ns_treatments.dart';
import 'package:carer/services/updaters/updater.dart';

class UpdateService {
  // is a singleton
  static final UpdateService _instance = UpdateService._();
  factory UpdateService() => _instance;

  List<Updater> updaters = [];
  UpdateService._() {
    var nsSummaryUpdater = NSSummaryUpdater()..start();
    var nsEntriesUpdater = NSEntriesUpdater()..start();
    var nsTreatmentUpdater = NSTreatmentsUpdater()..start();
    var nsProfileUpdater = NSProfileUpdater()..start();

    updaters.addAll([nsSummaryUpdater, nsEntriesUpdater, nsTreatmentUpdater, nsProfileUpdater]);
  }
}
