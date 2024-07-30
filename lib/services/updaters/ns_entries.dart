import 'package:carer/mappers/ns_to_models.dart';
import 'package:carer/mappers/sql_mappers.dart';
import 'package:carer/models/sgv.dart';
import 'package:carer/nsclient/nsclient.dart';
import 'package:carer/services/settings/secure_settings.dart';
import 'package:carer/services/updaters/updater.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/utils/logs.dart';

class NSEntriesUpdater extends Updater {
  NSEntriesUpdater() : super(intervalToCheck: const Duration(seconds: 1), maxAgeBeforeChecking: const Duration(minutes: 1)) {
    aeffect(() {
      // Check signal to register
      var _ = SecureSettings().nightscoutURL;
      addExternalReason("NS URL updated");
    });
  }

  @override
  List<String> shouldUpdate() {
    var reasons = super.shouldUpdate();

    var lastSGV = CleanSGV.lastSGV.value;
    if (lastSGV == null) {
      reasons.add("Last SGV is null");
    } else {
      var sgvage = lastSGV.age.inSeconds;

      // Check more frequently when the SGV is about to expire
      var fma = sgvage % 300;
      // If age is above 5 mins, the first 30 seconds, check every 2 seconds
      if (sgvage > 305 && fma > 0 && fma < 30 && fma % 2 == 0) {
        reasons.add("Last SGV is $sgvage's old ($fma's late)");
      }
    }
    return reasons;
  }

  @override
  Future<bool> update() async {
    var (nsURL, nsToken) = SecureSettings().nightscoutURLAndToken;

    // Get the last amount of readings with a few extra for certainty
    var gteCreatedAt = super.lastSuccessfulUpdate.subtract(const Duration(minutes: 10));
    var (entries, err) = await go(NSClient().getEntries(nsURL, nsToken, gteCreatedAt));
    if (err != null || entries == null) {
      return false;
    }

    raw = entries.raw;
    List<SGV> sgvs = const NSEntryToSGV().mapAToB(entries.entries);
    var total = await SQLToSGV().saveAll(sgvs);

    alog("Updated Entries $total");
    return true;
  }
}
