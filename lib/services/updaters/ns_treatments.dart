import 'package:carer/models/bolus.dart';
import 'package:carer/models/carbs.dart';
import 'package:carer/models/tempbasal.dart';
import 'package:carer/models/temptarget.dart';
import 'package:carer/nsclient/nsclient.dart';
import 'package:carer/services/settings/secure_settings.dart';
import 'package:carer/services/updaters/updater.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/utils/logs.dart';
import 'package:clock/clock.dart';

class NSTreatmentsUpdater extends Updater {
  // On first call backfill last two days
  bool _backfill = true;

  NSTreatmentsUpdater() : super(intervalToCheck: const Duration(seconds: 1), maxAgeBeforeChecking: const Duration(seconds: 10)) {
    lastSuccessfulUpdate = clock.daysAgo(1);
    aeffect(() {
      // Check signal to register
      var _ = SecureSettings().nightscoutURL;
      addExternalReason("NS URL updated");
    });
  }

  @override
  Future<bool> update() async {
    var (nsURL, nsToken) = SecureSettings().nightscoutURLAndToken;

    // Update so far back because past treatments may need to be updated
    var gteCreatedAt = super.lastSuccessfulUpdate.subtract(const Duration(minutes: 80));
    var (entries, err) = await go(NSClient().getTreatments(nsURL, nsToken, gteCreatedAt));
    if (err != null || entries == null) {
      return false;
    }

    alog("Retrieved ${entries.treatments.length} treatments");

    List<Bolus> boluses = [];
    for (var bolus in entries.boluses) {
      boluses.add(Bolus(
        value: bolus.insulin,
        date: bolus.date,
        eid: bolus.id,
      ));
    }
    int bolusUpdates = await Bolus.saveAll(boluses);

    List<Carbs> carbs = [];
    for (var carb in entries.carbs) {
      carbs.add(Carbs(
        value: carb.carbs.round(),
        date: carb.date,
        eid: carb.id,
      ));
    }
    int carbUpdates = await Carbs.saveAll(carbs);

    List<TempBasal> tempBasals = [];
    for (var tempBasal in entries.tempBasals) {
      tempBasals.add(TempBasal(
        startDate: tempBasal.date,
        duration: tempBasal.durationInMilliseconds ~/ 1000,
        value: tempBasal.absolute,
        eid: tempBasal.id,
      ));
    }
    int tempBasalUpdates = await TempBasal.upsertAll(tempBasals);

    List<TempTarget> tempTargets = [];
    for (var tempTarget in entries.tempTargets) {
      tempTargets.add(TempTarget(
          eid: tempTarget.id,
          startDate: tempTarget.date,
          duration: tempTarget.durationInMilliseconds ~/ 1000,
          highTarget: tempTarget.targetTop.toInt(),
          lowTarget: tempTarget.targetBottom.toInt()));
    }

    int tempTargetUpdates = await TempTarget.upsertAll(tempTargets);

    // summary is not trustworthy source of information
    // TODO replace summary as the source of information
    // var badTempBasals = await TempBasal.fixData();
    // var badTempTargets = await TempTarget.fixData();

    alog('''
update Treatments $bolusUpdates, $carbUpdates, $tempBasalUpdates, $tempTargetUpdates
          ''');

    _backfill = false;
    return true;
  }
}
