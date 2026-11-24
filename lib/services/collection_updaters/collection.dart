// An Updater Manages the time that the data is updated
import 'dart:async';

import 'package:clock/clock.dart';

// maxHistoryPages is the most pages of a history one update reads, as a long time offline can have many changes; the
// rest are read on the next update
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
  Future<bool> bootstrap();
}
