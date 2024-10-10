import 'package:carer/models/sql/db_model.dart';

class Alarm extends DBModel {
  @override
  final DateTime date;

  final String alarmValue;
  final String propertiesJSON;

  Alarm({
    super.id,
    required super.eid,
    required this.date,
    required this.alarmValue,
    required this.propertiesJSON,
  });
}
