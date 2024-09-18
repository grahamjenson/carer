import 'package:carer/models/model.dart';
import 'package:clock/clock.dart';

abstract class DBModel with DateMixin {
  int? id;
  String? eid;

  DBModel({this.id, this.eid});
}

abstract class DateRangeDBModel extends DBModel {
  @override
  get date => startDate;
  final DateTime startDate;

  final int duration;

  DateRangeDBModel({
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
