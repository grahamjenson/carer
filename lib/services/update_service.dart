import 'package:carer/services/updaters/ns_entries.dart';
import 'package:carer/services/updaters/ns_summary.dart';
import 'package:carer/services/updaters/ns_treatments.dart';
import 'package:carer/services/updaters/updater.dart';
import 'package:clock/clock.dart';

class UpdateService {
  // is a singleton
  static final UpdateService _instance = UpdateService._();
  factory UpdateService() => _instance;

  List<Updater> updaters = [];
  UpdateService._() {
    var nsSummaryUpdater = NSSummaryUpdater()..start();
    var nsEntriesUpdater = NSEntriesUpdater()..start();
    var nsTreatmentUpdater = NSTreatmentsUpdater()..start();

    updaters.addAll([nsSummaryUpdater, nsEntriesUpdater, nsTreatmentUpdater]);
  }
  // When this updates lots of things will change
  int summaryLastUpdatedMS = 0;
  int summaryAgeInSeconds() {
    var dateRetrieved = DateTime.fromMillisecondsSinceEpoch(summaryLastUpdatedMS);
    return clock.now().difference(dateRetrieved).inSeconds;
  }

  final bool _summaryToBeUpdated = true;

  final String _updateReason = "";
}
