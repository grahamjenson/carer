// An Updater Manages the time that the data is updated
import 'dart:async';

import 'package:carer/sql/key_value_store.dart';
import 'package:clock/clock.dart';

// maxHistoryPages is the most pages of a history one update reads, as a long time offline can have many changes; the
// rest are read on the next update, from where it stopped (readOnNextUpdate)
const maxHistoryPages = 10;

abstract class NSCollection {
  List<String> raw = [];
  String getCollectionName();
  int lastModifiedMilliSeconds = 0;

  bool updateForce = false;
  forceUpdate() {
    updateForce = true;
  }

  DateTime lastSuccessfulUpdate = clock.daysAgo(3);
  Duration get successfulAge => clock.now().difference(lastSuccessfulUpdate);

  // update reads what changed since lastModified, a srvModified, from the collection's history
  Future<bool> update(int lastModified);

  // The cursor, lastModifiedMilliSeconds, is kept for the Nightscout at nsURL, so after Carer restarts its next update
  // reads what changed while it was closed, deletions too, rather than only the 10 minutes before. Another Nightscout
  // starts with none.
  String _cursorKey(String nsURL) => "nsLastModified_${getCollectionName()}_$nsURL";

  Future<void> loadCursor(String nsURL) async {
    lastModifiedMilliSeconds = (await KeyValueStore.instance).getInt(_cursorKey(nsURL)) ?? 0;
  }

  Future<void> saveCursor(String nsURL) async {
    await (await KeyValueStore.instance).setInt(_cursorKey(nsURL), lastModifiedMilliSeconds);
  }

  // readOnNextUpdate is an update that read maxHistoryPages pages and stopped at srvModified since: false, so the next
  // update starts there, rather than at the collection's last change, which would skip the changes not read
  bool readOnNextUpdate(int since) {
    lastModifiedMilliSeconds = since;
    return false;
  }
  Future<bool> bootstrap();
}
