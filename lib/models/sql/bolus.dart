import 'package:carer/models/sql/db_model.dart';

class Bolus extends DBModel {
  final double value;
  @override
  final DateTime date;

  Bolus({
    super.id,
    required super.eid,
    required this.value,
    required this.date,
  });
}
