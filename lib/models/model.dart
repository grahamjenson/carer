import 'package:clock/clock.dart';

mixin DateMixin {
  DateTime get date;

  Duration get age {
    return clock.now().difference(date);
  }

  int get minsAgo => age.inMinutes;
  int get minsFromNow => -age.inMinutes;

  int get minuteTimestamp => date.millisecondsSinceEpoch ~/ 60000;

  // This returns the minsAgo bucket for last 5 mins
  int get fiveMinsAgoBucket => minsAgo - (minsAgo % 5);
}
