import 'package:clock/clock.dart';

abstract class Model {
  int? id;
  String? eid;

  Model({this.id, this.eid});
  DateTime get date;

  Duration get age {
    return clock.now().difference(date);
  }

  int get minsAgo => (clock.now().millisecondsSinceEpoch - date.millisecondsSinceEpoch) ~/ 60000;
  int get minsFromNow => (date.millisecondsSinceEpoch - clock.now().millisecondsSinceEpoch) ~/ 60000;
}

abstract class DateRangeModel extends Model {
  @override
  get date => startDate;
  final DateTime startDate;

  final int duration;

  DateRangeModel({
    super.id,
    super.eid,
    required this.startDate,
    required this.duration,
  });

  Duration get remaining {
    return endDate.difference(clock.now());
  }

  bool isAtTime(DateTime date) {
    return date.isAfter(startDate) && date.isBefore(endDate);
  }

  DateTime get endDate => startDate.add(Duration(seconds: duration));
}
