// An Updater Manages the time that the data is updated
import 'dart:async';

import 'package:clock/clock.dart';

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

  Future<bool> update(int lastModified);
  Future<bool> bootstrap();
}
