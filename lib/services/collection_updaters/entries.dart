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

  // update reads what changed since a srvModified, page by page, from the entries' history, so readings uploaded late,
  // after a phone was offline, are not missed, and ones deleted are removed
  @override
  Future<bool> update(int lastModified) async {
    var (nsURL, nsToken) = SecureSettings().nightscoutURLAndToken;

    var since = lastModified;
    for (var page = 0; page < maxHistoryPages; page++) {
      var (entries, err) = await go(NSClient().getEntries(nsURL, nsToken, since, historySince: since));
      // An empty raw is a request that failed, so the same changes are asked for again
      if (err != null || entries == null || entries.raw.isEmpty) {
        return false;
      }

      raw.add(entries.raw);

      List<SGV> sgvs = const NSEntryToSGV().mapAToB(entries.entries);
      var total = await SQLToSGV().saveAll(sgvs);
      var deleted = await SQLToSGV().deleteByEids(entries.deletedIds);
      alog("entries: entry Total ${entries.entries.length}, Updated $total, Deleted $deleted");

      var last = entries.lastSrvModified;
      if (entries.count < historyLimit || last == null || last <= since) {
        return true;
      }
      since = last;
    }
    return true;
  }
}
