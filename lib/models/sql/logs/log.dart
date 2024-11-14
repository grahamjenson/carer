import 'package:carer/models/sql/db_model.dart';

abstract class LogDBModel extends DBModel {
  @override
  get date => startDate;

  final DateTime startDate;
  DateTime? endDate;
  final Map<String, dynamic> conditions;

  LogDBModel({
    super.id,
    super.eid,
    required this.startDate,
    this.endDate,
    required this.conditions,
  });
}
