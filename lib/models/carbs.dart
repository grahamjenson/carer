import 'package:carer/models/model.dart';

class Carbs extends Model {
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
