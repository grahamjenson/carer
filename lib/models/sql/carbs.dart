import 'package:carer/models/sql/db_model.dart';

class Carbs extends DBModel {
  final int value;
  @override
  final DateTime date;

  Carbs({
    super.id,
    required super.eid,
    required this.value,
    required this.date,
  });
}
