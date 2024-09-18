import 'package:carer/models/sql/db_model.dart';

class SGV extends DBModel {
  final int value;

  @override
  final DateTime date;

  SGV({
    required this.value,
    required this.date,
    required super.eid,
    super.id,
  });
}
