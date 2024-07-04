import 'package:carer/models/bolus.dart';
import 'package:carer/models/carbs.dart';
import 'package:carer/models/tempbasal.dart';
import 'package:carer/models/temptarget.dart';
import 'package:carer/nsclient/nsclient.dart';
import 'package:carer/services/settings/settings.dart';
import 'package:carer/services/updaters/updater.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/utils/logs.dart';

class NSTreatmentsUpdater extends Updater {
  // On first call backfill last two days
  bool _backfill = true;

  NSTreatmentsUpdater() : super(intervalToCheck: const Duration(seconds: 1), maxAgeBeforeChecking: const Duration(seconds: 2)) {
    aeffect(() {
      // Check signal to register
      var _ = Settings().nightscoutURL;
      addExternalReason("NS URL updated");
    });
  }

  @override
  Future<bool> update() async {
    var (nsURL, nsToken) = Settings().nightscoutURLAndToken;
    var count = 12; // last hour
    if (_backfill) {
      count = 1000;
    }

    var (entries, err) = await go(NSClient().getTreatments(nsURL, nsToken, count));
    if (err != null || entries == null) {
      return false;
    }

    alog("${entries.treatments.length} treatments");

    List<Bolus> boluses = [];
    for (var bolus in entries.boluses) {
      boluses.add(Bolus(value: bolus.insulin, date: bolus.date));
    }
    int bolusUpdates = await Bolus.saveAll(boluses);

    List<Carbs> carbs = [];
    for (var carb in entries.carbs) {
      carbs.add(Carbs(value: carb.carbs.round(), date: carb.date));
    }
    int carbUpdates = await Carbs.saveAll(carbs);

    List<TempBasal> tempBasals = [];
    for (var tempBasal in entries.tempBasals) {
      tempBasals.add(TempBasal(startDate: tempBasal.date, duration: tempBasal.durationInMilliseconds ~/ 1000, value: tempBasal.absolute));
    }
    int tempBasalUpdates = await TempBasal.saveAll(tempBasals);

    List<TempTarget> tempTargets = [];
    for (var tempTarget in entries.tempTargets) {
      tempTargets.add(TempTarget(
          startDate: tempTarget.date,
          duration: tempTarget.durationInMilliseconds ~/ 1000,
          highTarget: tempTarget.targetTop.toInt(),
          lowTarget: tempTarget.targetBottom.toInt()));
    }
    int tempTargetUpdates = await TempTarget.saveAll(tempTargets);

    // summary is not trustworthy source of information
    // TODO replace summary as the source of information
    var badTempBasals = await TempBasal.fixData();
    var badTempTargets = await TempTarget.fixData();

    alog('''
update Treatments $bolusUpdates, $carbUpdates, $tempBasalUpdates, $tempTargetUpdates
Bad data $badTempBasals, $badTempTargets
          ''');

    _backfill = false;
    return true;
  }
}
