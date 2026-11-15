import 'package:carer/mappers/ns/entry.dart';
import 'package:carer/mappers/sql/sgv.dart';
import 'package:carer/models/sql/sgv.dart';
import 'package:carer/nsclient/nsclient.dart';
import 'package:carer/services/collection_updaters/collection.dart';
import 'package:carer/services/settings/secure_settings.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/utils/logs.dart';
import 'package:clock/clock.dart';

class NSEntriesUpdater extends NSCollection {
  @override
  String getCollectionName() {
    return "entries";
  }

  @override
  Future<bool> bootstrap() async {
    var (nsURL, nsToken) = SecureSettings().nightscoutURLAndToken;

    // Get the last amount of readings with a few extra for certainty
    var lookbacktime = clock.hoursAgo(24).millisecondsSinceEpoch;

    var (entries, err) = await go(NSClient().getEntries(nsURL, nsToken, lookbacktime));
    if (err != null || entries == null) {
      return false;
    }

    raw.add(entries.raw);

    List<SGV> sgvs = const NSEntryToSGV().mapAToB(entries.entries);
    var total = await SQLToSGV().saveAll(sgvs);

    alog("Bootstrap entries: Total ${entries.entries.length}, Updated $total");
    return true;
  }

  @override
  Future<bool> update(int lastModified) async {
    var (nsURL, nsToken) = SecureSettings().nightscoutURLAndToken;

    // Get the last amount of readings with a few extra for certainty
    var (entries, err) = await go(NSClient().getEntries(nsURL, nsToken, lastModified));
    if (err != null || entries == null) {
      return false;
    }

    raw.add(entries.raw);

    List<SGV> sgvs = const NSEntryToSGV().mapAToB(entries.entries);
    var total = await SQLToSGV().saveAll(sgvs);

    alog("entries: entry Total ${entries.entries.length}, Updated $total");
    return true;
  }
}
