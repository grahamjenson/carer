import 'package:clock/clock.dart';

mixin DateMixin {
  DateTime get date;

  Duration get age {
    return clock.now().difference(date);
  }

  int get minsAgo => age.inMinutes;
  int get minsFromNow => -age.inMinutes;

  int get minuteTimestamp => date.millisecondsSinceEpoch ~/ 60000;

  // This returns the minsAgo window for last 5 mins
  int bucketFor(int window) => minuteTimestamp - (minuteTimestamp % window);

  bool get isDuringToday {
    final now = clock.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final startOfTomorrow = startOfToday.add(const Duration(days: 1));
    return date.isAfter(startOfToday) && date.isBefore(startOfTomorrow);
  }

  bool get isDuringYesterday {
    final now = clock.now();
    final startOfYesterday = DateTime(now.year, now.month, now.day - 1);
    final startOfToday = DateTime(now.year, now.month, now.day);
    return date.isAfter(startOfYesterday) && date.isBefore(startOfToday);
  }
}
