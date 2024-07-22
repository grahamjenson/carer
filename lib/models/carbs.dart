import 'package:carer/models/model.dart';

class Carbs extends Model {
  @override
  ModelRepository get repository => throw UnimplementedError();

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
